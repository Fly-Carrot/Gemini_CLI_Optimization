#import <Cocoa/Cocoa.h>
#import <dispatch/dispatch.h>
#import <signal.h>
#import <sys/ioctl.h>
#import <util.h>

static NSString *ShellEscapeSingleQuoted(NSString *value) {
  NSString *escaped = [value stringByReplacingOccurrencesOfString:@"'" withString:@"'\"'\"'"];
  return [NSString stringWithFormat:@"'%@'", escaped];
}

static NSString *StripANSIAndNormalize(NSString *input) {
  if (input.length == 0) {
    return @"";
  }

  NSMutableString *working = [input mutableCopy];

  NSError *error = nil;
  NSRegularExpression *osc = [NSRegularExpression regularExpressionWithPattern:@"\\x1B\\][^\\x07]*(\\x07|\\x1B\\\\)" options:0 error:&error];
  if (osc && !error) {
    [osc replaceMatchesInString:working options:0 range:NSMakeRange(0, working.length) withTemplate:@""];
  }

  error = nil;
  NSRegularExpression *csi = [NSRegularExpression regularExpressionWithPattern:@"\\x1B\\[[0-9;?]*[ -/]*[@-~]" options:0 error:&error];
  if (csi && !error) {
    [csi replaceMatchesInString:working options:0 range:NSMakeRange(0, working.length) withTemplate:@""];
  }

  [working replaceOccurrencesOfString:@"\r\n" withString:@"\n" options:0 range:NSMakeRange(0, working.length)];
  [working replaceOccurrencesOfString:@"\r" withString:@"\n" options:0 range:NSMakeRange(0, working.length)];

  NSMutableString *result = [NSMutableString string];
  for (NSUInteger i = 0; i < working.length; i++) {
    unichar ch = [working characterAtIndex:i];
    if (ch == 0x08 || ch == 0x7F) {
      if (result.length > 0) {
        [result deleteCharactersInRange:NSMakeRange(result.length - 1, 1)];
      }
      continue;
    }
    if (ch < 0x20 && ch != '\n' && ch != '\t') {
      continue;
    }
    [result appendFormat:@"%C", ch];
  }

  return result;
}

@interface TerminalTextView : NSTextView
@property(nonatomic, copy) void (^keyInputHandler)(NSString *text);
@end

@implementation TerminalTextView

- (BOOL)isOpaque {
  return YES;
}

- (BOOL)acceptsFirstResponder {
  return YES;
}

- (void)mouseDown:(NSEvent *)event {
  [self.window makeFirstResponder:self];
  [super mouseDown:event];
}

- (void)keyDown:(NSEvent *)event {
  if ((event.modifierFlags & NSEventModifierFlagCommand) == NSEventModifierFlagCommand) {
    [super keyDown:event];
    return;
  }

  if (!self.keyInputHandler) {
    [super keyDown:event];
    return;
  }

  NSString *text = nil;
  switch (event.keyCode) {
    case 36:
      text = @"\r";
      break;
    case 48:
      text = @"\t";
      break;
    case 51:
      text = @"\x7F";
      break;
    case 53:
      text = @"\x1B";
      break;
    case 123:
      text = @"\x1B[D";
      break;
    case 124:
      text = @"\x1B[C";
      break;
    case 125:
      text = @"\x1B[B";
      break;
    case 126:
      text = @"\x1B[A";
      break;
    default:
      text = event.characters ?: @"";
      break;
  }

  if (text.length > 0) {
    self.keyInputHandler(text);
  }
}

@end

@interface StyledButton : NSButton
@end

@implementation StyledButton

- (instancetype)initWithFrame:(NSRect)frameRect {
  self = [super initWithFrame:frameRect];
  if (self) {
    self.bordered = NO;
    self.font = [NSFont systemFontOfSize:12 weight:NSFontWeightSemibold];
    self.wantsLayer = YES;
    self.layer.cornerRadius = 12.0;
    self.layer.backgroundColor = [NSColor colorWithCalibratedWhite:0.12 alpha:1.0].CGColor;
    self.contentTintColor = [NSColor colorWithCalibratedWhite:0.96 alpha:1.0];
  }
  return self;
}

@end

@interface DarkPopUpButton : NSPopUpButton
@end

@implementation DarkPopUpButton

- (instancetype)initWithFrame:(NSRect)frameRect pullsDown:(BOOL)flag {
  self = [super initWithFrame:frameRect pullsDown:flag];
  if (self) {
    self.wantsLayer = YES;
    self.layer.cornerRadius = 10.0;
    self.layer.backgroundColor = [NSColor colorWithCalibratedWhite:0.10 alpha:1.0].CGColor;
    self.font = [NSFont systemFontOfSize:12 weight:NSFontWeightMedium];
  }
  return self;
}

@end

@interface GeminiShellSession : NSObject
@property(nonatomic, copy) NSString *workspacePath;
@property(nonatomic, copy) NSString *globalFabricRoot;
@property(nonatomic, assign) int masterFD;
@property(nonatomic, assign) pid_t childPID;
@property(nonatomic, strong) dispatch_source_t readSource;
@property(nonatomic, assign) BOOL booted;
@property(nonatomic, copy) void (^outputHandler)(NSString *text);
@property(nonatomic, copy) void (^statusHandler)(NSString *text);
- (instancetype)initWithWorkspacePath:(NSString *)workspacePath;
- (void)bootIfNeeded;
- (void)startShellWithModel:(NSString *)model effort:(NSString *)effort;
- (void)restartShellWithModel:(NSString *)model effort:(NSString *)effort;
- (void)sendText:(NSString *)text;
- (void)stopShell;
- (NSString *)settingsPathForEffort:(NSString *)effort;
@end

@implementation GeminiShellSession

- (instancetype)initWithWorkspacePath:(NSString *)workspacePath {
  self = [super init];
  if (self) {
    self.workspacePath = workspacePath;
    self.globalFabricRoot = @"/Users/david_chen/Antigravity_Skills/global-agent-fabric";
    self.masterFD = -1;
    self.childPID = -1;
    self.booted = NO;
  }
  return self;
}

- (NSString *)settingsPathForEffort:(NSString *)effort {
  NSString *filename = @"gemini-2-app-effort-high.json";
  if ([effort isEqualToString:@"Low"]) {
    filename = @"gemini-2-app-effort-low.json";
  } else if ([effort isEqualToString:@"Medium"]) {
    filename = @"gemini-2-app-effort-medium.json";
  }
  return [self.workspacePath stringByAppendingPathComponent:filename];
}

- (void)bootIfNeeded {
  if (self.booted) {
    if (self.statusHandler) {
      self.statusHandler(@"Ready");
    }
    return;
  }

  NSString *timestamp = [[NSISO8601DateFormatter new] stringFromDate:[NSDate date]];
  NSString *safeTimestamp = [timestamp stringByReplacingOccurrencesOfString:@":" withString:@"-"];
  NSString *taskId = [NSString stringWithFormat:@"gemini2-native-ui-%@", safeTimestamp];
  NSString *preflight = [self.globalFabricRoot stringByAppendingPathComponent:@"scripts/sync/preflight_check.py"];
  NSString *syncAll = [self.globalFabricRoot stringByAppendingPathComponent:@"scripts/sync/sync_all.py"];

  if (self.statusHandler) {
    self.statusHandler(@"Bootstrapping shared fabric...");
  }

  [self runOneShot:@"/usr/bin/python3"
         arguments:@[
           preflight, @"--global-root", self.globalFabricRoot,
           @"--workspace", self.workspacePath,
           @"--agent", @"gemini-2-app",
           @"--task-id", taskId,
         ]
       completion:^(BOOL success) {
         if (!success) {
           if (self.outputHandler) {
             self.outputHandler(@"[BOOT_WARN] preflight_check.py failed. Continuing with local shell.\n");
           }
           if (self.statusHandler) {
             self.statusHandler(@"Running without boot sync");
           }
           return;
         }

         [self runOneShot:@"/usr/bin/python3"
                arguments:@[
                  syncAll, @"--global-root", self.globalFabricRoot,
                  @"--workspace", self.workspacePath,
                  @"--agent", @"gemini-2-app",
                  @"--task-id", taskId,
                  @"--skip-export",
                ]
              completion:^(BOOL syncSuccess) {
                if (syncSuccess) {
                  self.booted = YES;
                  if (self.outputHandler) {
                    self.outputHandler(@"[BOOT_OK] Shared fabric boot finished for Gemini-2.app\n");
                  }
                  if (self.statusHandler) {
                    self.statusHandler(@"Ready");
                  }
                } else {
                  if (self.outputHandler) {
                    self.outputHandler(@"[BOOT_WARN] sync_all.py failed. Continuing with local shell.\n");
                  }
                  if (self.statusHandler) {
                    self.statusHandler(@"Running without sync receipt");
                  }
                }
              }];
       }];
}

- (void)runOneShot:(NSString *)path
         arguments:(NSArray<NSString *> *)arguments
        completion:(void (^)(BOOL success))completion {
  NSTask *task = [[NSTask alloc] init];
  task.launchPath = path;
  task.arguments = arguments;
  task.currentDirectoryPath = self.workspacePath;

  NSPipe *outputPipe = [NSPipe pipe];
  task.standardOutput = outputPipe;
  task.standardError = outputPipe;

  outputPipe.fileHandleForReading.readabilityHandler = ^(NSFileHandle *handle) {
    NSData *data = handle.availableData;
    if (data.length == 0) {
      return;
    }
    NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (text.length > 0 && self.outputHandler) {
      dispatch_async(dispatch_get_main_queue(), ^{
        self.outputHandler(text);
      });
    }
  };

  task.terminationHandler = ^(NSTask *finishedTask) {
    outputPipe.fileHandleForReading.readabilityHandler = nil;
    dispatch_async(dispatch_get_main_queue(), ^{
      completion(finishedTask.terminationStatus == 0);
    });
  };

  @try {
    [task launch];
  } @catch (NSException *exception) {
    if (self.outputHandler) {
      self.outputHandler([NSString stringWithFormat:@"Failed to run %@: %@\n", path.lastPathComponent, exception.reason ?: @"unknown error"]);
    }
    completion(NO);
  }
}

- (void)startShellWithModel:(NSString *)model effort:(NSString *)effort {
  [self stopShell];

  struct winsize windowSize;
  windowSize.ws_row = 40;
  windowSize.ws_col = 140;
  windowSize.ws_xpixel = 0;
  windowSize.ws_ypixel = 0;

  int fd = -1;
  pid_t pid = forkpty(&fd, NULL, NULL, &windowSize);
  if (pid == -1) {
    if (self.outputHandler) {
      self.outputHandler(@"Failed to create terminal session.\n");
    }
    return;
  }

  if (pid == 0) {
    chdir([self.workspacePath fileSystemRepresentation]);
    setenv("TERM", "xterm-256color", 1);
    setenv("COLORTERM", "truecolor", 1);
    setenv("GEMINI2_SKIP_BOOT", "1", 1);
    setenv("GEMINI2_SHARED_FABRIC_WORKSPACE", [self.workspacePath UTF8String], 1);
    setenv("AGF_WORKSPACE", [self.workspacePath UTF8String], 1);
    setenv("GEMINI_MODEL", [model UTF8String], 1);
    setenv("GEMINI_CLI_SYSTEM_SETTINGS_PATH", [[self settingsPathForEffort:effort] UTF8String], 1);
    execl("/bin/zsh", "zsh", "-il", NULL);
    _exit(1);
  }

  self.masterFD = fd;
  self.childPID = pid;

  dispatch_queue_t queue = dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0);
  self.readSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, (uintptr_t)fd, 0, queue);

  __weak typeof(self) weakSelf = self;
  dispatch_source_set_event_handler(self.readSource, ^{
    typeof(self) strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }

    char buffer[4096];
    ssize_t bytesRead = read(fd, buffer, sizeof(buffer));
    if (bytesRead > 0) {
      NSData *data = [NSData dataWithBytes:buffer length:(NSUInteger)bytesRead];
      NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
      NSString *cleaned = StripANSIAndNormalize(text ?: @"");
      if (cleaned.length > 0 && strongSelf.outputHandler) {
        dispatch_async(dispatch_get_main_queue(), ^{
          strongSelf.outputHandler(cleaned);
        });
      }
    } else if (bytesRead == 0) {
      dispatch_source_cancel(strongSelf.readSource);
    }
  });

  dispatch_source_set_cancel_handler(self.readSource, ^{
    close(fd);
  });

  dispatch_resume(self.readSource);

  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    NSString *banner = @"printf '\\nGemini-2 native shell ready. Click here to type directly, or use the message bar below. Prefix ! to run raw shell commands.\\n\\n'\r";
    [weakSelf sendText:banner];
  });
}

- (void)restartShellWithModel:(NSString *)model effort:(NSString *)effort {
  if (self.outputHandler) {
    self.outputHandler(@"\n[session] restarting shell with current model and effort settings...\n");
  }
  [self startShellWithModel:model effort:effort];
}

- (void)sendText:(NSString *)text {
  if (self.masterFD < 0 || text.length == 0) {
    return;
  }
  NSData *data = [text dataUsingEncoding:NSUTF8StringEncoding];
  if (data.length > 0) {
    write(self.masterFD, data.bytes, data.length);
  }
}

- (void)stopShell {
  if (self.childPID > 0) {
    kill(self.childPID, SIGTERM);
    self.childPID = -1;
  }
  if (self.readSource) {
    dispatch_source_cancel(self.readSource);
    self.readSource = nil;
  }
  self.masterFD = -1;
}

@end

@interface AppController : NSObject <NSApplicationDelegate, NSTextFieldDelegate>
@property(nonatomic, strong) NSWindow *window;
@property(nonatomic, strong) TerminalTextView *terminalView;
@property(nonatomic, strong) NSTextField *inputField;
@property(nonatomic, strong) NSTextField *hintLabel;
@property(nonatomic, strong) NSTextField *statusLabel;
@property(nonatomic, strong) DarkPopUpButton *modelSelector;
@property(nonatomic, strong) DarkPopUpButton *effortSelector;
@property(nonatomic, strong) GeminiShellSession *session;
@end

@implementation AppController

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
  NSString *workspacePath = [NSBundle.mainBundle.bundlePath stringByDeletingLastPathComponent];
  self.session = [[GeminiShellSession alloc] initWithWorkspacePath:workspacePath];
  [self buildWindow];

  __weak typeof(self) weakSelf = self;
  self.session.outputHandler = ^(NSString *text) {
    [weakSelf appendTerminalText:text];
  };
  self.session.statusHandler = ^(NSString *text) {
    weakSelf.statusLabel.stringValue = text ?: @"";
  };

  [self.session bootIfNeeded];
  [self.session startShellWithModel:self.modelSelector.selectedItem.title effort:self.effortSelector.selectedItem.title];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
  return YES;
}

- (void)applicationWillTerminate:(NSNotification *)notification {
  [self.session stopShell];
}

- (void)buildWindow {
  NSRect frame = NSMakeRect(0, 0, 1320, 860);
  self.window = [[NSWindow alloc] initWithContentRect:frame
                                            styleMask:(NSWindowStyleMaskTitled |
                                                       NSWindowStyleMaskClosable |
                                                       NSWindowStyleMaskMiniaturizable |
                                                       NSWindowStyleMaskResizable |
                                                       NSWindowStyleMaskFullSizeContentView)
                                              backing:NSBackingStoreBuffered
                                                defer:NO];
  self.window.title = @"";
  self.window.titleVisibility = NSWindowTitleHidden;
  self.window.titlebarAppearsTransparent = YES;
  self.window.movableByWindowBackground = YES;
  [self.window center];

  NSView *contentView = self.window.contentView;
  contentView.wantsLayer = YES;
  contentView.layer.backgroundColor = [NSColor colorWithCalibratedWhite:0.02 alpha:1.0].CGColor;

  CGFloat width = frame.size.width;
  CGFloat height = frame.size.height;
  CGFloat sidebarWidth = 220.0;

  NSView *sidebar = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, sidebarWidth, height)];
  sidebar.wantsLayer = YES;
  sidebar.layer.backgroundColor = [NSColor colorWithCalibratedWhite:0.05 alpha:1.0].CGColor;
  sidebar.autoresizingMask = NSViewHeightSizable;
  [contentView addSubview:sidebar];

  NSTextField *sidebarLabel = [NSTextField labelWithString:@"Quick Actions"];
  sidebarLabel.font = [NSFont systemFontOfSize:13 weight:NSFontWeightSemibold];
  sidebarLabel.textColor = [NSColor colorWithCalibratedWhite:0.75 alpha:1.0];
  sidebarLabel.frame = NSMakeRect(22, height - 54, sidebarWidth - 44, 18);
  sidebarLabel.autoresizingMask = NSViewMinYMargin;
  [sidebar addSubview:sidebarLabel];

  NSArray<NSDictionary *> *buttonSpecs = @[
    @{ @"title": @"Long Task", @"selector": NSStringFromSelector(@selector(insertLongTaskTemplate:)) },
    @{ @"title": @"Runtime", @"selector": NSStringFromSelector(@selector(insertRuntimeTemplate:)) },
    @{ @"title": @"Skills", @"selector": NSStringFromSelector(@selector(insertSkillsTemplate:)) },
    @{ @"title": @"Agents", @"selector": NSStringFromSelector(@selector(insertAgentsTemplate:)) },
    @{ @"title": @"Restart", @"selector": NSStringFromSelector(@selector(restartShell:)) },
  ];

  CGFloat buttonY = height - 94;
  for (NSDictionary *spec in buttonSpecs) {
    StyledButton *button = [[StyledButton alloc] initWithFrame:NSMakeRect(22, buttonY, sidebarWidth - 44, 34)];
    button.title = spec[@"title"];
    button.target = self;
    button.action = NSSelectorFromString(spec[@"selector"]);
    button.autoresizingMask = NSViewMinYMargin | NSViewWidthSizable;
    [sidebar addSubview:button];
    buttonY -= 46;
  }

  NSTextField *modelLabel = [NSTextField labelWithString:@"Model"];
  modelLabel.font = [NSFont systemFontOfSize:11 weight:NSFontWeightMedium];
  modelLabel.textColor = [NSColor colorWithCalibratedWhite:0.65 alpha:1.0];
  modelLabel.frame = NSMakeRect(22, 190, sidebarWidth - 44, 16);
  modelLabel.autoresizingMask = NSViewMaxYMargin;
  [sidebar addSubview:modelLabel];

  self.modelSelector = [[DarkPopUpButton alloc] initWithFrame:NSMakeRect(22, 156, sidebarWidth - 44, 30) pullsDown:NO];
  [self.modelSelector addItemsWithTitles:@[@"auto", @"flash", @"pro"]];
  [self.modelSelector selectItemWithTitle:@"pro"];
  self.modelSelector.autoresizingMask = NSViewMaxYMargin | NSViewWidthSizable;
  [self.modelSelector setTarget:self];
  [self.modelSelector setAction:@selector(settingsChanged:)];
  [sidebar addSubview:self.modelSelector];

  NSTextField *effortLabel = [NSTextField labelWithString:@"Effort"];
  effortLabel.font = [NSFont systemFontOfSize:11 weight:NSFontWeightMedium];
  effortLabel.textColor = [NSColor colorWithCalibratedWhite:0.65 alpha:1.0];
  effortLabel.frame = NSMakeRect(22, 118, sidebarWidth - 44, 16);
  effortLabel.autoresizingMask = NSViewMaxYMargin;
  [sidebar addSubview:effortLabel];

  self.effortSelector = [[DarkPopUpButton alloc] initWithFrame:NSMakeRect(22, 84, sidebarWidth - 44, 30) pullsDown:NO];
  [self.effortSelector addItemsWithTitles:@[@"Low", @"Medium", @"High"]];
  [self.effortSelector selectItemWithTitle:@"High"];
  self.effortSelector.autoresizingMask = NSViewMaxYMargin | NSViewWidthSizable;
  [self.effortSelector setTarget:self];
  [self.effortSelector setAction:@selector(settingsChanged:)];
  [sidebar addSubview:self.effortSelector];

  self.statusLabel = [NSTextField labelWithString:@"Booting..."];
  self.statusLabel.font = [NSFont systemFontOfSize:11 weight:NSFontWeightMedium];
  self.statusLabel.textColor = [NSColor colorWithCalibratedWhite:0.58 alpha:1.0];
  self.statusLabel.frame = NSMakeRect(22, 50, sidebarWidth - 44, 16);
  self.statusLabel.autoresizingMask = NSViewMaxYMargin | NSViewWidthSizable;
  [sidebar addSubview:self.statusLabel];

  self.hintLabel = [NSTextField labelWithString:@"Long Task lets Gemini-2 keep iterating automatically on a bigger goal."];
  self.hintLabel.font = [NSFont systemFontOfSize:11 weight:NSFontWeightRegular];
  self.hintLabel.textColor = [NSColor colorWithCalibratedWhite:0.50 alpha:1.0];
  self.hintLabel.frame = NSMakeRect(22, 14, sidebarWidth - 44, 30);
  self.hintLabel.lineBreakMode = NSLineBreakByWordWrapping;
  self.hintLabel.maximumNumberOfLines = 2;
  self.hintLabel.autoresizingMask = NSViewMaxYMargin | NSViewWidthSizable;
  [sidebar addSubview:self.hintLabel];

  CGFloat terminalX = sidebarWidth + 18;
  CGFloat terminalWidth = width - terminalX - 18;

  NSScrollView *terminalScroll = [[NSScrollView alloc] initWithFrame:NSMakeRect(terminalX, 84, terminalWidth, height - 112)];
  terminalScroll.borderType = NSNoBorder;
  terminalScroll.hasVerticalScroller = YES;
  terminalScroll.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
  terminalScroll.wantsLayer = YES;
  terminalScroll.layer.backgroundColor = [NSColor blackColor].CGColor;
  terminalScroll.contentView.wantsLayer = YES;
  terminalScroll.contentView.layer.backgroundColor = [NSColor blackColor].CGColor;

  self.terminalView = [[TerminalTextView alloc] initWithFrame:terminalScroll.contentView.bounds];
  self.terminalView.editable = NO;
  self.terminalView.selectable = YES;
  self.terminalView.automaticQuoteSubstitutionEnabled = NO;
  self.terminalView.automaticDataDetectionEnabled = NO;
  self.terminalView.automaticLinkDetectionEnabled = NO;
  self.terminalView.font = [NSFont monospacedSystemFontOfSize:14 weight:NSFontWeightRegular];
  self.terminalView.backgroundColor = [NSColor blackColor];
  self.terminalView.textColor = [NSColor colorWithCalibratedWhite:0.96 alpha:1.0];
  self.terminalView.insertionPointColor = [NSColor colorWithCalibratedRed:0.85 green:0.90 blue:1.0 alpha:1.0];
  self.terminalView.textContainerInset = NSMakeSize(16, 18);
  self.terminalView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;

  __weak typeof(self) weakSelf = self;
  self.terminalView.keyInputHandler = ^(NSString *text) {
    [weakSelf.session sendText:text];
  };

  terminalScroll.documentView = self.terminalView;
  [contentView addSubview:terminalScroll];

  NSView *inputBar = [[NSView alloc] initWithFrame:NSMakeRect(terminalX, 16, terminalWidth, 50)];
  inputBar.wantsLayer = YES;
  inputBar.layer.backgroundColor = [NSColor colorWithCalibratedWhite:0.06 alpha:1.0].CGColor;
  inputBar.layer.cornerRadius = 16.0;
  inputBar.autoresizingMask = NSViewWidthSizable | NSViewMaxYMargin;
  [contentView addSubview:inputBar];

  self.inputField = [[NSTextField alloc] initWithFrame:NSMakeRect(16, 11, terminalWidth - 100, 28)];
  self.inputField.placeholderString = @"Message Gemini-2 here. Prefix ! to run a raw shell command.";
  self.inputField.font = [NSFont systemFontOfSize:14 weight:NSFontWeightRegular];
  self.inputField.bordered = NO;
  self.inputField.drawsBackground = NO;
  self.inputField.textColor = [NSColor colorWithCalibratedWhite:0.96 alpha:1.0];
  self.inputField.focusRingType = NSFocusRingTypeNone;
  self.inputField.autoresizingMask = NSViewWidthSizable;
  self.inputField.target = self;
  self.inputField.action = @selector(sendInput:);
  [inputBar addSubview:self.inputField];

  StyledButton *sendButton = [[StyledButton alloc] initWithFrame:NSMakeRect(terminalWidth - 70, 9, 54, 32)];
  sendButton.title = @"Send";
  sendButton.target = self;
  sendButton.action = @selector(sendInput:);
  sendButton.autoresizingMask = NSViewMinXMargin;
  [inputBar addSubview:sendButton];

  [self.window makeKeyAndOrderFront:nil];
  [NSApp activateIgnoringOtherApps:YES];
  [self.window makeFirstResponder:self.terminalView];
}

- (void)settingsChanged:(id)sender {
  self.statusLabel.stringValue = [NSString stringWithFormat:@"Next command: %@ · %@", self.modelSelector.selectedItem.title, self.effortSelector.selectedItem.title];
}

- (void)insertLongTaskTemplate:(id)sender {
  [self applyTemplate:@"/loop run " hint:@"Long Task: describe a bigger goal after this prefix. Gemini-2 will keep stepping until done, blocked, or it hits the loop limit."];
}

- (void)insertRuntimeTemplate:(id)sender {
  [self applyTemplate:@"/runtime status" hint:@"Runtime: shows the current runtime, loop, memory, and session state."];
}

- (void)insertSkillsTemplate:(id)sender {
  [self applyTemplate:@"/skills active" hint:@"Skills: shows which shared-fabric skills are active in the current Gemini-2 context."];
}

- (void)insertAgentsTemplate:(id)sender {
  [self applyTemplate:@"/agents list" hint:@"Agents: shows which agents are available for delegation right now."];
}

- (void)restartShell:(id)sender {
  self.hintLabel.stringValue = @"Restart: starts a fresh shell session. Current model and effort settings apply to the next Gemini-2 command.";
  [self.session restartShellWithModel:self.modelSelector.selectedItem.title effort:self.effortSelector.selectedItem.title];
}

- (void)applyTemplate:(NSString *)template hint:(NSString *)hint {
  NSString *current = [self.inputField.stringValue stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
  if (current.length == 0) {
    self.inputField.stringValue = template;
  } else if (![current hasPrefix:template]) {
    self.inputField.stringValue = [NSString stringWithFormat:@"%@%@", template, current];
  }
  self.hintLabel.stringValue = hint;
  [self.window makeFirstResponder:self.inputField];
  NSText *editor = [self.window fieldEditor:YES forObject:self.inputField];
  if ([editor respondsToSelector:@selector(setSelectedRange:)]) {
    [(NSTextView *)editor setSelectedRange:NSMakeRange(self.inputField.stringValue.length, 0)];
  }
}

- (void)sendInput:(id)sender {
  NSString *raw = [self.inputField.stringValue stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
  if (raw.length == 0) {
    return;
  }

  NSString *line = nil;
  if ([raw hasPrefix:@"!"]) {
    NSString *shellCommand = [[raw substringFromIndex:1] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    line = [NSString stringWithFormat:@"%@\r", shellCommand];
    self.hintLabel.stringValue = @"Raw shell mode: sent directly to the terminal session.";
  } else {
    NSString *model = self.modelSelector.selectedItem.title ?: @"pro";
    NSString *effortPath = [self.session settingsPathForEffort:self.effortSelector.selectedItem.title ?: @"High"];
    NSString *command = [NSString stringWithFormat:@"GEMINI_MODEL=%@ GEMINI_CLI_SYSTEM_SETTINGS_PATH=%@ ./gemini-2 --model %@ --prompt %@\r",
      ShellEscapeSingleQuoted(model),
      ShellEscapeSingleQuoted(effortPath),
      ShellEscapeSingleQuoted(model),
      ShellEscapeSingleQuoted(raw)];
    line = command;
    self.hintLabel.stringValue = @"Prompt mode: wrapped your message into a one-shot Gemini-2 CLI command.";
  }

  self.inputField.stringValue = @"";
  [self.session sendText:line];
  [self.window makeFirstResponder:self.terminalView];
}

- (void)appendTerminalText:(NSString *)text {
  if (text.length == 0) {
    return;
  }
  NSAttributedString *attributed = [[NSAttributedString alloc] initWithString:text attributes:@{
    NSForegroundColorAttributeName: [NSColor colorWithCalibratedWhite:0.96 alpha:1.0]
  }];
  [self.terminalView.textStorage appendAttributedString:attributed];
  [self.terminalView scrollToEndOfDocument:nil];
}

@end

int main(int argc, const char *argv[]) {
  @autoreleasepool {
    NSApplication *app = [NSApplication sharedApplication];
    AppController *delegate = [[AppController alloc] init];
    app.delegate = delegate;
    [app setActivationPolicy:NSApplicationActivationPolicyRegular];
    [app run];
  }
  return 0;
}

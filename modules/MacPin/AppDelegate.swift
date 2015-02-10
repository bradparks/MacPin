extension MacPin: NSApplicationDelegate {
	//optional func applicationDockMenu(_ sender: NSApplication) -> NSMenu?

	public func applicationShouldOpenUntitledFile(app: NSApplication) -> Bool { return false }

	public func applicationWillFinishLaunching(notification: NSNotification) { // dock icon bounces, also before self.openFile(foo.bar) is called
		NSUserNotificationCenter.defaultUserNotificationCenter().delegate = self
		app = notification.object as? NSApplication
		
		app!.mainMenu = NSMenu()

		var appMenu = NSMenuItem()
		appMenu.submenu = NSMenu()
		appMenu.submenu?.easyAddItem("Quit \(NSProcessInfo.processInfo().processName)", "terminate:", "q")
		appMenu.submenu?.easyAddItem("About", "orderFrontStandardAboutPanel:")
		appMenu.submenu?.easyAddItem("", "toggleFullScreen:")
		appMenu.submenu?.easyAddItem("Toggle Translucency", "toggleTransparency")
		appMenu.submenu?.easyAddItem("", "toggleToolbarShown:")
		appMenu.submenu?.easyAddItem("Load Site App", "loadSiteApp")
		appMenu.submenu?.easyAddItem("Edit Site App...", "editSiteApp")
		app!.mainMenu?.addItem(appMenu) // 1st item shows up as CFPrintableName

		var editMenu = NSMenuItem()
		editMenu.submenu = NSMenu()
		editMenu.submenu?.title = "Edit"
		editMenu.submenu?.easyAddItem("Cut", "cut:", "x", [.CommandKeyMask]) 
		editMenu.submenu?.easyAddItem("Copy", "copy:", "c", [.CommandKeyMask]) 
		editMenu.submenu?.easyAddItem("Paste", "paste:", "p", [.CommandKeyMask])
		editMenu.submenu?.easyAddItem("Select All", "selectAll:", "a", [.CommandKeyMask])
		app!.mainMenu?.addItem(editMenu) 

		var tabMenu = NSMenuItem()
		tabMenu.submenu = NSMenu()
		tabMenu.submenu?.title = "Tab"
		tabMenu.submenu?.easyAddItem("Enter URL", "focusOnURLBox", "l", [.CommandKeyMask])
		tabMenu.submenu?.easyAddItem("Zoom In", "zoomIn", "+", [.CommandKeyMask])
		tabMenu.submenu?.easyAddItem("Zoom Out", "zoomOut", "-", [.CommandKeyMask])
		// title: "Open Web Inspector", action: Selector("showConsole:"),
		tabMenu.submenu?.easyAddItem("Reload", "reloadFromOrigin:", "R", [.CommandKeyMask])
		tabMenu.submenu?.easyAddItem("Close Tab", "closeCurrentTab", "w", [.CommandKeyMask])
		tabMenu.submenu?.easyAddItem("Go Back", "goBack", "[", [.CommandKeyMask])
		tabMenu.submenu?.easyAddItem("Go Forward", "goForward", "]", [.CommandKeyMask])	
		tabMenu.submenu?.easyAddItem("Print", "print:")
		tabMenu.submenu?.easyAddItem("Stop Loading", "stopLoading:", String(format:"%c", 27))  //ESC
		app!.mainMenu?.addItem(tabMenu) 

		var winMenu = NSMenuItem()
		winMenu.submenu = NSMenu()
		winMenu.submenu?.title = "Window"
		winMenu.submenu?.easyAddItem("Open New Tab", "newTabPrompt", "t", [.CommandKeyMask])
		winMenu.submenu?.easyAddItem("Show Next Tab", "selectNextTabViewItem:", String(format:"%c", NSTabCharacter), [.ControlKeyMask]) // \t
		winMenu.submenu?.easyAddItem("Show Previous Tab", "selectPreviousTabViewItem:", String(format:"%c", NSTabCharacter), [.ControlKeyMask, .ShiftKeyMask])
		app!.mainMenu?.addItem(winMenu) 

		var origDnD = class_getInstanceMethod(WKView.self, "performDragOperation:")
		var newDnD = class_getInstanceMethod(WKView.self, "shimmedPerformDragOperation:")
		method_exchangeImplementations(origDnD, newDnD) //swizzle that shizzlee to enable logging of DnD's

		showApplication(self) //configure window and view controllers
	}

    public func applicationDidFinishLaunching(notification: NSNotification?) { //dock icon stops bouncing
		loadSiteApp()

		if let notification = notification {
			if let userNotification = notification.userInfo?["NSApplicationLaunchUserNotificationKey"] as? NSUserNotification {
				userNotificationCenter(NSUserNotificationCenter.defaultUserNotificationCenter(), didActivateNotification: userNotification)
			}
		}
    }

	public func applicationDidBecomeActive(notification: NSNotification) {
		//if application?.orderedDocuments?.count < 1 { showApplication(self) }
	}

	public func applicationWillTerminate(notification: NSNotification) { NSUserDefaults.standardUserDefaults().synchronize() }
    
	public func applicationShouldTerminateAfterLastWindowClosed(app: NSApplication) -> Bool { return true }
}

extension MacPin: NSUserNotificationCenterDelegate {
	//didDeliverNotification
	public func userNotificationCenter(center: NSUserNotificationCenter, didActivateNotification notification: NSUserNotification) {
		conlog("user clicked notification")

		if _jsapi.tryFunc("handleClickedNotification", notification.title ?? "", notification.subtitle ?? "", notification.informativeText ?? "") {
			conlog("handleClickedNotification fired!")
			center.removeDeliveredNotification(notification)
		}
		//NSWorkspace.sharedWorkspace().openURL(NSURL(string: notification.subtitle ?? "")!)
	}

	// always display notifcations, even if app is active in foreground (for alert sounds)
	public func userNotificationCenter(center: NSUserNotificationCenter, shouldPresentNotification notification: NSUserNotification) -> Bool { return true }
}

extension MacPin: NSSharingServicePickerDelegate { }

extension MacPin: NSWindowDelegate {
	// these just handle tabless-background drags
	func draggingEntered(sender: NSDraggingInfo) -> NSDragOperation { return NSDragOperation.Every }
	func performDragOperation(sender: NSDraggingInfo) -> Bool { return true }
	//func cancelOperation(sender: AnyObject?) { NSApplication.sharedApplication().sendAction(Selector("stopLoading"), to: nil, from: sender) }
}

extension MacPin: NSWindowRestoration {
	class public func restoreWindowWithIdentifier(identifier: String, state: NSCoder, completionHandler: ((NSWindow!,NSError!) -> Void)) {
		warn("restoreWindowWithIdentifier: \(identifier)") // state: \(state)")
		switch identifier {
			case "browser":
				var appdel = (NSApplication.sharedApplication().delegate as MacPin)
				completionHandler(appdel.windowController.window!, nil)
			default:
				//have app remake window from scratch
				completionHandler(nil, nil) //FIXME: should ret an NSError
		}
	}
}
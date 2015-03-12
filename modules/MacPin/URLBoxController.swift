import WebKit
public extension WKWebView {
	override func setValue(value: AnyObject?, forUndefinedKey key: String) {
		if key != "URL" { super.setValue(value, forUndefinedKey: key) } //prevents URLbox from trying to directly rewrite webView.URL
	}
}

import Cocoa

class URLAddressField: NSTextField {
	var isLoading: Bool = false { didSet { needsDisplay = true } }
	var progress: Double = Double(0.0) { didSet { needsDisplay = true } }

	override func drawRect(dirtyRect: NSRect) {
		if isLoading {
			// draw a Safari style progress-line
			//var progressRect = NSOffsetRect(bounds, 0, 4) //along top
			var progressRect = NSOffsetRect(bounds, 0, NSMaxY(bounds) - 4) //along bottom
			progressRect.size.height = 4
			progressRect.size.width *= CGFloat(progress)

			NSColor(calibratedRed:0.0, green: 0.0, blue: 1.0, alpha: 0.4).set()
			NSRectFillUsingOperation(progressRect, .CompositeSourceOver)
		} else {
			//NSRectFillUsingOperation(bounds, .CompositeClear)
			NSRectFillUsingOperation(bounds, .CompositeCopy)
		}
		super.drawRect(dirtyRect)
	}
}

class URLBoxController: NSViewController {	
	let urlbox = URLAddressField()

	override var representedObject: AnyObject? {
		didSet { //KVC to copy updates to webviews url & title (user navigations, history.pushState(), window.title=)
			if let representedObject: AnyObject = representedObject {
				view.bind(NSToolTipBinding, toObject: representedObject, withKeyPath: "view.title", options: nil)
				view.bind(NSValueBinding, toObject: representedObject, withKeyPath: "view.URL", options: nil)
				view.bind(NSFontBoldBinding, toObject: representedObject, withKeyPath: "view.hasOnlySecureContent", options: nil)
				view.bind("isLoading", toObject: representedObject, withKeyPath: "view.isLoading", options: nil)
				view.bind("progress", toObject: representedObject, withKeyPath: "view.estimatedProgress", options: nil)
				if let focusObj = representedObject as? NSViewController {
					nextResponder = focusObj
					view.nextKeyView = focusObj.view
				}
			}
		}
		willSet(newro) { 
			if let representedObject: AnyObject = representedObject {
				nextResponder = nil
				view.nextKeyView = nil
				view.unbind(NSToolTipBinding)
				view.unbind(NSValueBinding)
				view.unbind(NSFontBoldBinding)
				view.unbind("progress")
				view.unbind("isLoading")
			}
		}
	}

	required init?(coder: NSCoder) { super.init(coder: coder) }
	override init?(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) { super.init(nibName:nil, bundle:nil) } // calls loadView() 
	override func loadView() { view = urlbox } // NIBless
 
	init(webViewController: WebViewController?) {
		super.init() //calls init(nibName) via ??
		preferredContentSize = CGSize(width: 600, height: 24) //app hangs on view presentation without this!
		if let wvc = webViewController { representedObject = wvc }
	}

	override func viewDidLoad() {
		super.viewDidLoad()
 		// prepareForReuse() {...} ?
		urlbox.wantsLayer = true
		urlbox.bezelStyle = .RoundedBezel
		urlbox.drawsBackground = false
		urlbox.textColor = NSColor.controlTextColor() 
		urlbox.toolTip = ""
		//urlbox.wantsLayer = true
		//urlbox.editable = false
		//urlbox.menu = NSMenu //ctrl-click context menu

		urlbox.delegate = self

		if let cell = urlbox.cell() as? NSTextFieldCell {
			cell.placeholderString = "Navigate to URL"
			cell.scrollable = true
			cell.action = Selector("userEnteredURL")
			//cell.target = nil // on Enter, send action up the Responder chain
			cell.target = self
			cell.sendsActionOnEndEditing = false //only send action when Return is pressed
			cell.usesSingleLineMode = true
			cell.focusRingType = .None
			//cell.currentEditor()?.delegate = self // do live validation of input URL before Enter is pressed
		}

		// should have a grid of all tabs below the urlbox, safari style. NSCollectionView?
		// https://developer.apple.com/library/mac/samplecode/GridMenu/Listings/ReadMe_txt.html#//apple_ref/doc/uid/DTS40010559-ReadMe_txt-DontLinkElementID_14
		// or just show a segmented tabcontrol if clicking in the urlbox?
	}

	override func viewWillAppear() {
		super.viewWillAppear()
	}

	override func viewDidAppear() {
		super.viewDidAppear()
	}

	func userEnteredURL() {
		var urlstr = (view as NSTextField).stringValue
		if let url = validateURL(urlstr) {
			if let wvc = representedObject? as? WebViewController { //would be cool if I could just kick up gotoURL to nextResponder as NSResponder
				view.window?.makeFirstResponder(wvc.view) //makes no difference if this vc was brought up as a modal sheet
				wvc.gotoURL(url as NSURL)
				cancelOperation(self)
			}
		} else {
			warn("\(__FUNCTION__): invalid url `\(urlstr)` was requested!")
			//NSBeep()
		}
	}
	
	override func cancelOperation(sender: AnyObject?) { presentingViewController?.dismissViewController(self) } //if a thoust art a popover, close thyself

	deinit { representedObject = nil }
}

extension URLBoxController: NSTextFieldDelegate {
	//func textShouldBeginEditing(textObject: NSText) -> Bool { return true } //allow editing
	//func textDidChange(aNotification: NSNotification)
	func textShouldEndEditing(textObject: NSText) -> Bool { //user attempting to focus out of field
		if let url = validateURL(textObject.string ?? "") { return true } //allow focusout
		warn("\(__FUNCTION__): invalid url entered: \(textObject.string)")
		return false //NSBeep()s, keeps focus
	}
	//func textDidEndEditing(aNotification: NSNotification) {	}
}

extension URLBoxController: NSPopoverDelegate {	
	func popoverWillShow(notification: NSNotification) {
		//urlbox.sizeToFit() //fixme: makes the box undersized sometimes
	}
}

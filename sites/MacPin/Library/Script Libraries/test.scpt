JsOsaDAS1.001.00bplist00�Vscript_�function test(args) {
	var script = Application.currentApplication();
	script.includeStandardAdditions = true;
	script.displayNotification('JXA library!', { withTitle: 'test', subtitle: 'Done' });
	script.displayAlert('library tested!');
	return args;
}
                               jscr  ��ޭ
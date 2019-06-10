set bundles to {}
tell application "System Events"
	set names to get the name of every process whose visible is true
end tell
repeat with name in names
	set bundles to bundles & id of application name
end repeat
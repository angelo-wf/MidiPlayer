
SWIFTC = swiftc

execname = MidiPlayer
bundlename = MidiPlayer.app

swiftfiles = main.swift AppDelegate.swift ViewController.swift

.PHONY: all clean

all: $(bundlename)

$(execname): $(swiftfiles)
	$(SWIFTC) -o $@ $(swiftfiles)

$(bundlename): $(execname)
	rm -rf $(bundlename)
	mkdir -p $(bundlename)/Contents/MacOS
	mkdir -p $(bundlename)/Contents/Frameworks
	mkdir -p $(bundlename)/Contents/Resources
	cp $(execname) $(bundlename)/Contents/MacOS/$(execname)
	cp macos/appicon.icns $(bundlename)/Contents/Resources/appicon.icns
	cp macos/PkgInfo $(bundlename)/Contents/PkgInfo
	cp macos/Info.plist $(bundlename)/Contents/Info.plist

clean:
	rm -f $(execname)
	rm -rf $(bundlename)

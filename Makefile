PROJECT = 'DemoApp/DemoApp.xcodeproj'
SCHEME = 'DemoApp'
DESTINATION = 'platform=iOS Simulator,name=iPhone 6s'

clean:
	xcodebuild \
		-project $(PROJECT) \
		clean

test:
	xcodebuild \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-destination $(DESTINATION) \
		build test

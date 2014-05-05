PROJECT = DemoApp/DemoApp.xcodeproj
SCHEME = DemoApp
TEST_SDK = iphonesimulator
CONFIGURATION_DEBUG = Debug

clean:
	xcodebuild \
		-project $(PROJECT) \
		clean

test:
	xcodebuild \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-sdk $(TEST_SDK) \
		-configuration $(CONFIGURATION_DEBUG) \
		build test

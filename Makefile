# Build the Swift project
build:
	@if [ "$$(id -u)" != "0" ]; then \
		echo "Please run as root"; \
		exit 1; \
	fi
	@echo "Building the project..."
	@cd ZeroTrustLanMonitor && xcodebuild -scheme ZeroTrustLanMonitor -configuration Release -derivedDataPath build
	@echo "Moving the binary to /usr/local/bin..."
	@cp -f ./ZeroTrustLanMonitor/build/Build/Products/Release/ZeroTrustLanMonitor /usr/local/bin/zerotrust-lanmonitor
	@echo "Done! The project has been built"

# Load the service on the system (MacOS only)
load:
	@echo "Loading the service..."
	@sudo launchctl bootstrap system /Library/LaunchDaemons/com.lucadibello.zerotrust-lanmonitor.plist
	@echo "Done! The service is now installed and running"
	@echo " [!] Please run 'make verify' to verify if the service is running. If it's not, please check the logs at /var/log/zerotrust-lanmonitor-error.log and /var/log/zerotrust-lanmonitor-output.log"
	@echo "You can now remove the cloned repository"

# Install the service on the system (MacOS only)
install: build
	@if [ "$$(id -u)" != "0" ]; then \
		echo "Please run as root"; \
		exit 1; \
	fi
	@if [ -f /etc/zerotrust-lanmonitor/.installed ]; then \
		echo "The service is already installed"; \
		exit 1; \
	fi
	@echo "Installing the service..."
	@mkdir -p /etc/zerotrust-lanmonitor
	@mkdir -p /opt/zerotrust-lanmonitor
	@mkdir -p /var/log
	@echo "Creating empty log files..."
	@touch /var/log/zerotrust-lanmonitor-error.log
	@touch /var/log/zerotrust-lanmonitor-output.log
	@echo "Moving the necessary files to the right location..."
	@cp -f ./config.json /etc/zerotrust-lanmonitor/config.json
	@cp -f ./enforce-lan-zerotrust.sh /opt/zerotrust-lanmonitor/enforce-lan-zerotrust.sh
	@cp -f ./com.lucadibello.zerotrust-lanmonitor.plist /Library/LaunchDaemons/com.lucadibello.zerotrust-lanmonitor.plist
	
	@echo "Setting the right permissions..."

	@chown root:wheel /Library/LaunchDaemons/com.lucadibello.zerotrust-lanmonitor.plist
	@chown -R root:wheel /etc/zerotrust-lanmonitor
	@chown root:wheel /var/log/zerotrust-lanmonitor-error.log
	@chown root:wheel /var/log/zerotrust-lanmonitor-output.log

	@chmod 755 /opt/zerotrust-lanmonitor/enforce-lan-zerotrust.sh
	@chmod 644 /etc/zerotrust-lanmonitor/config.json
	@chmod 644 /Library/LaunchDaemons/com.lucadibello.zerotrust-lanmonitor.plist
	@chmod 644 /var/log/zerotrust-lanmonitor-error.log
	@chmod 644 /var/log/zerotrust-lanmonitor-output.log
	@chmod +x /opt/zerotrust-lanmonitor/enforce-lan-zerotrust.sh

	@make load
	@touch /etc/zerotrust-lanmonitor/.installed

# Uninstall the service from the system (MacOS only)
uninstall:
	@if [ "$$(id -u)" != "0" ]; then \
		echo "Please run as root"; \
		exit 1; \
	fi
	@echo "Uninstalling the service..."
	@rm -rf /etc/zerotrust-lanmonitor
	@rm -rf /opt/zerotrust-lanmonitor
	@rm -f /Library/LaunchDaemons/com.lucadibello.zerotrust-lanmonitor.plist
	@rm -f /var/log/zerotrust-lanmonitor-error.log
	@rm -f /var/log/zerotrust-lanmonitor-output.log
	@rm -f /usr/local/bin/zerotrust-lanmonitor
	@echo "Done! The service has been uninstalled"
	@make unload	
	
# Unload the service from the system (MacOS only)
unload:
	@if [ "$$(id -u)" != "0" ]; then \
		echo "Please run as root"; \
		exit 1; \
	fi
	@echo "Unloading the service..."
	@launchctl bootout system /Library/LaunchDaemons/com.lucadibello.zerotrust-lanmonitor.plist
	@echo "Done! The service is now unloaded"

# Verify if the service is running
verify:
	@echo "Verifying the service..."
	@launchctl list | grep com.lucadibello.zerotrust-lanmonitor
	@echo "Done! The service is running"

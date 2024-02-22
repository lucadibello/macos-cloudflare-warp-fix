install:
	@if [ "$$(id -u)" != "0" ]; then \
		echo "Please run as root"; \
		exit 1; \
	fi
	@echo "Installing the service..."
	@mkdir -p /etc/zerotrust-lanmonitor
	@echo "Moving the necessary files to the right location..."
	@cp -f ./config.json /etc/zerotrust-lanmonitor/config.json
	@cp -f ./enforce-lan-zerotrust.sh /etc/zerotrust-lanmonitor/enforce-lan-zerotrust.sh

	@echo "Moving the service file to the right location (launchd)..."
if ! grep -q "abc_set_ssh_agent" /config/.bashrc; then
	printf "\n\n" >> /config/.bashrc
	cat '/custom-cont-init.d/bashrc' >> /config/.bashrc
fi

if ! grep -q "abc_set_ssh_agent" /config/.zshrc; then
	printf "\n\n" >> /config/.zshrc
	cat '/custom-cont-init.d/zshrc' >> /config/.zshrc
fi

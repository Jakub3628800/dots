.PHONY: packages

packages:
	ansible-playbook ansible/install-packages.yaml -i ansible/hosts --ask-become-pass

caps2esc:
	ansible-playbook ansible/caps2esc.yaml -i ansible/hosts --ask-become-pass

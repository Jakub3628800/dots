# Dotfiles repository



## Setup
1. Create and activate python virtual environment
```bash
python3 -m venv env && source env/bin/activate
```
2. Install requirements
```bash
pip install -r requirements.txt
```
3. Set up pre-commit
```bash
pre-commit install
```
4. Init links between files
```bash
bash init_links.sh
```


## caps2esc
https://gitlab.com/interception/linux/plugins/caps2esc#installation
https://www.dannyguo.com/blog/remap-caps-lock-to-escape-and-control/#linux

1. Install
```bash
sudo add-apt-repository ppa:deafmute/interception
sudo apt install interception-caps2esc
```

2. Add this job to `/etc/udevmon.yaml`
```bash
- JOB: "intercept -g $DEVNODE | caps2esc | uinput -d $DEVNODE"
  DEVICE:
    EVENTS:
      EV_KEY: [KEY_CAPSLOCK, KEY_ESC]
```

3. Start udevmon process with systemd
```bash
sudo systemctl enable udevmon
```

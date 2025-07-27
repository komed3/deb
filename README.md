# Komed3 Debian package source

Package source for projects by [komed3](https://komed3.de)

## Add package source

```bash
wget -O - https://deb.komed3.de/public.key | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/komed3.gpg
echo "deb [signed-by=/etc/apt/trusted.gpg.d/komed3.gpg] https://deb.komed3.de stable main" | sudo tee /etc/apt/sources.list.d/komed3.list
sudo apt update
```

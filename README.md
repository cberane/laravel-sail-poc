# Proof Of Concept to use sail

## My manual steps

## Development Setups for this project

- login to wsl  
  `wsl -d debian`
- setup sail
  ```bash
  bash setup-sail.sh
  ```
- install `nginx/certs/development-ca.crt` as trusted root certificate
  - this is needed to access the development site via trusted https
- `docker compose up`
  - to get the container running

Open
- Unprotected: http://localhost 
- Encrypted: https://localhost  

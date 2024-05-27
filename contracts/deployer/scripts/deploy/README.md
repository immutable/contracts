## Deployment

Build
```
nvm use 18.16
yarn
forge build
```

Create `.env` file:
```
cp .env.example .env
```

### Deployment
```
npx ts-node rbac_deployment.ts

npx ts-node create2_deployment.ts

npx ts-node create3_deployment.ts
```

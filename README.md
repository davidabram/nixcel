```bash
nix develop
```

```bash
nix develop --command pnpm dev
```
### Build 

```bash
nix develop --command bazel build //:next_build
```

### Build and Load Docker Image

```bash
nix develop --command bazel run //images:next_image_tarball
```

### Run Docker Container

```bash
docker run -p 3000:3000 nixcel-nonsense:latest
```

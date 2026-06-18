# Production Docker Best Practices (MNC Standards)

When MNCs deploy containerized applications, they enforce strict guidelines regarding **security, image size, and build performance**. Below are the key strategies implemented in our setup:

---

## 1. Multi-Stage Builds
In our [Dockerfile](file:///C:/Users/Hitesh/.gemini/antigravity/scratch/devops-mastery/phase2-docker/Dockerfile):
- **Stage 1 (Builder)** contains development tooling (Composer, Node package managers, compiler utilities). This stage builds and installs dependencies.
- **Stage 2 (Runtime)** starts from a bare-minimum production base image (`php:8.2-fpm-alpine`). We only copy the built production-ready files (`vendor/` directory and application code) from the Builder stage.
- **Result**: The build tools, source control history, and documentation are excluded from the final image, reducing image sizes by up to 80% (making deployments and scaling much faster).

---

## 2. Docker Layer Caching
Docker builds run sequentially. Each command creates a layer. If a layer changes, all subsequent layers are invalidated and must be rebuilt.
- **MNC Strategy**: Copy files that change least frequently first (like package manifests: `composer.json` or `package.json`), run package installation (`composer install` or `npm install`), and then copy application source code.
- **Result**: When you change your application code, Docker does not reinstall dependencies. It reuses the cached dependency layer, reducing build times from minutes to seconds.

---

## 3. Container Security Hardening
Running containers as `root` is a critical vulnerability. If an attacker compromises your application, they gain root access to the host machine.
- **MNC Strategy**: Create or use an unprivileged system user (`www-data` or a custom user) and switch execution context:
  ```dockerfile
  USER www-data
  ```
- Use light-weight, minimal distributions like **Alpine Linux** or **Google's Distroless** images. They contain a very small attack surface (fewer binaries, shell utilities, and system packages).

---

## 4. Key Interview Question: Networking Differences

During senior DevOps interviews, you will often be asked:
> *"How does Nginx communicate with PHP-FPM in a Docker Compose environment vs. a Kubernetes Cluster?"*

Here is the architectural explanation:

### Scenario A: Docker Compose (Multi-Container Networking)
- **Architecture**: Nginx and PHP-FPM run in separate containers. Each container gets its own isolated network interface and IP address.
- **Networking**: They communicate via the Docker bridge network. Nginx resolves the hostname using Docker's internal DNS.
- **Configuration**:
  ```nginx
  fastcgi_pass app:9000; # 'app' is the service name in docker-compose.yml
  ```

### Scenario B: Kubernetes Pod (Shared Network Namespace)
- **Architecture**: Nginx and PHP-FPM run as two containers inside the **same Pod** (called the **Sidecar Pattern**).
- **Networking**: All containers in a single Pod share the same network namespace, loopback interface, and IP address.
- **Configuration**:
  ```nginx
  fastcgi_pass 127.0.0.1:9000; # They talk directly via localhost!
  ```

# 🤝 Contributing to Ubuntu Power Management Suite

Thank you for your interest in contributing! This project follows professional development practices to maintain code quality and reliability.

## 🔄 Development Workflow

### Branch Strategy
We use **Git Flow** for branch management:

- **`main`** - Stable releases only
- **`develop`** - Integration branch for features
- **`feature/*`** - New features and enhancements
- **`hotfix/*`** - Critical fixes for production
- **`release/*`** - Prepare new releases

### Getting Started

1. **Fork the repository**
   ```bash
   gh repo fork DiegoNogueiraDev/ubuntu-power-management
   ```

2. **Clone your fork**
   ```bash
   git clone https://github.com/YOUR_USERNAME/ubuntu-power-management.git
   cd ubuntu-power-management
   ```

3. **Set up development environment**
   ```bash
   git remote add upstream https://github.com/DiegoNogueiraDev/ubuntu-power-management.git
   git checkout develop
   ```

4. **Create a feature branch**
   ```bash
   git checkout -b feature/amazing-new-feature
   ```

## 📋 Contribution Guidelines

### Code Standards

- **Shell Scripts**: Follow [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- **Functions**: Include docstrings and error handling
- **Logging**: Use consistent logging format `[TIMESTAMP] LEVEL: message`
- **Security**: Never commit sensitive data or hardcoded credentials

### Hardware Support

When adding support for new hardware:

1. **Update hardware-detector.sh** with new detection logic
2. **Add configuration templates** in appropriate format
3. **Update compatibility matrix** in README.md
4. **Test on real hardware** when possible
5. **Document limitations** clearly

### Testing Requirements

Before submitting:

```bash
# Test hardware detection
./scripts/hardware-detector.sh detect

# Verify compatibility report
./scripts/hardware-detector.sh report

# Test installation (in VM recommended)
./ubuntu-power-installer.sh --dry-run

# Check all scripts are executable
find scripts/ -name "*.sh" -exec file {} \; | grep -v executable
```

### Commit Guidelines

Use **Conventional Commits** format:

```
type(scope): brief description

detailed explanation if needed

- change 1
- change 2
```

**Types:**
- `feat`: New features
- `fix`: Bug fixes
- `docs`: Documentation updates  
- `style`: Code formatting
- `refactor`: Code restructuring
- `test`: Adding tests
- `chore`: Maintenance tasks

**Examples:**
```bash
git commit -m "feat(gpu): add NVIDIA RTX 4000 series support

- Add detection for RTX 4070/4080/4090
- Include power limit configuration
- Update compatibility matrix"

git commit -m "fix(battery): resolve threshold detection on ThinkPads

- Fix path detection for newer ThinkPad models
- Add fallback for legacy battery interfaces
- Improve error handling for missing sysfs entries"
```

## 🔧 Development Areas

### High Priority
- **Intel GPU optimization** improvements
- **NVIDIA GPU power management** enhancements  
- **Battery threshold support** for more laptop models
- **Thermal management** for different CPU architectures
- **PowerTop integration** improvements

### Medium Priority
- **GUI application** for easier configuration
- **Systemd service** optimization
- **Performance benchmarking** tools
- **Configuration validation** system
- **Automated testing** framework

### Hardware Testing Needed
- **Intel 12th/13th gen** processors
- **NVIDIA RTX 4000 series** GPUs
- **AMD Ryzen 7000 series** processors
- **Framework Laptop** compatibility
- **System76** laptop testing

## 🐛 Bug Reports

When reporting bugs, include:

1. **Hardware information**
   ```bash
   ./scripts/hardware-detector.sh report > hardware-report.txt
   ```

2. **System information**
   ```bash
   uname -a
   lsb_release -a
   ```

3. **Error logs**
   ```bash
   tail -50 ~/power-management/logs/*.log
   ```

4. **Steps to reproduce**
5. **Expected vs actual behavior**

## 🚀 Feature Requests

For new features:

1. **Check existing issues** for duplicates
2. **Describe the use case** clearly
3. **Propose implementation approach**
4. **Consider hardware compatibility**
5. **Estimate complexity and impact**

## 📝 Documentation

- **README.md** - User-facing documentation
- **DEVELOPER_GUIDE.md** - Technical implementation details
- **Code comments** - Explain complex logic
- **Hardware notes** - Document quirks and limitations

## ⚡ Performance Considerations

- **Script execution time** should be minimal
- **System resource usage** must be lightweight
- **Battery impact** of monitoring should be negligible
- **Memory usage** should be constant
- **CPU overhead** must be less than 1%

## 🔒 Security Guidelines

- **Never commit credentials** or sensitive data
- **Use minimal privileges** in scripts
- **Validate all inputs** thoroughly
- **Handle errors gracefully** without exposing internals
- **Audit system modifications** before applying

## 📦 Release Process

1. **Feature freeze** on develop branch
2. **Create release branch** from develop
3. **Update version numbers** and documentation
4. **Test thoroughly** on supported systems
5. **Merge to main** and tag release
6. **Create GitHub release** with changelog

## 💬 Communication

- **GitHub Discussions** - General questions and ideas
- **GitHub Issues** - Bug reports and feature requests
- **Pull Request reviews** - Code feedback and suggestions
- **Commit messages** - Clear, descriptive communication

## 🏆 Recognition

Contributors are recognized in:
- **README.md** contributors section
- **Release notes** for significant contributions
- **Code comments** for complex implementations
- **GitHub contributors** graph

## 📚 Learning Resources

- [TLP Documentation](https://linrunner.de/tlp/)
- [Linux Power Management](https://www.kernel.org/doc/html/latest/power/)
- [AMD P-State Driver](https://docs.kernel.org/admin-guide/pm/amd-pstate.html)
- [Intel P-State Guide](https://www.kernel.org/doc/html/latest/admin-guide/pm/intel_pstate.html)

---

Thank you for contributing to make Ubuntu power management better for everyone! 🙏

If you have questions, feel free to open a discussion or reach out to maintainers.

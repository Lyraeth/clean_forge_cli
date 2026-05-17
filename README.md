# Clean Forge CLI

A Dart CLI for generating Flutter Clean Architecture boilerplate.

## Project structure

- `bin/clean_forge_cli.dart`: executable entry point for `forge` and `gen`.
- `lib/src/runner.dart`: command routing.
- `lib/src/commands/`: CLI command implementations.
- `lib/src/config.dart`: `clean_config.json` loading and writing.
- `lib/src/template_engine.dart`: `.stub` rendering.

## Usage

Initialize a Flutter project:

```bash
forge init
```

Generate a feature skeleton:

```bash
forge make:feature auth
```

The command can also add `presentation/widgets` when prompted.

Generate an entity from `stubs/entity.stub`:

```bash
forge make:entity User -f auth
```

Generate an entity into a nested folder and choose the feature interactively:

```bash
forge make:entity user_entity /user_entity
```

Generate a model from `stubs/model.stub`:

```bash
forge make:model User -f auth
```

Custom field prompts accept this format:

```txt
String id -r
String email -r
String alamat -o
String fullName -r --key="full_name"
bool isActive -r --key="is_active" --default=true
```

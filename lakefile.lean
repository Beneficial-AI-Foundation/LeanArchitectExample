import Lake
open Lake DSL

package ExampleProject

@[default_target]
lean_lib Example where
  globs := #[.submodules `Example]

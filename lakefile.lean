import Lake
open Lake DSL

package ExampleProject

require LeanArchitect from git
  "https://github.com/hanwenzhu/LeanArchitect.git" @ "main"

@[default_target]
lean_lib Example where
  globs := #[.submodules `Example]

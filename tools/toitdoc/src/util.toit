// Copyright (C) 2024 Toitware ApS.
//
// This library is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public
// License as published by the Free Software Foundation; version
// 2.1 only.
//
// This library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Lesser General Public License for more details.
//
// The license can be found in the file `LICENSE` in the top level
// directory of this repository.

import encoding.yaml
import fs
import host.file

import ..lsp-exports as lsp

resolve-class-ref ref/lsp.ToplevelRef --summaries/Map -> lsp.Class:
  target-module/lsp.Module := summaries[ref.module-uri]
  return (target-module.toplevel-element-with-id ref.id) as lsp.Class

resolve-function-ref ref/lsp.ToplevelRef --summaries/Map -> lsp.Method:
  target-module/lsp.Module := summaries[ref.module-uri]
  return (target-module.toplevel-element-with-id ref.id) as lsp.Method

resolve-global-ref ref/lsp.ToplevelRef --summaries/Map -> lsp.Method:
  return resolve-function-ref ref --summaries=summaries

/**
Loads the package names from the package.yaml file.

Returns null, if the project URI is null, or we can't find the package.lock file.
*/
load-package-names project-uri/string? -> Map?:
  if not project-uri: return null

  // Load the package names from the package.yaml file.
  lock-path := fs.join (lsp.to-path project-uri) "package.lock"
  if not file.is-file lock-path: return null

  data := file.read-content lock-path
  decoded := yaml.decode data

  result := {:}
  packages := decoded["packages"]
  packages.do: | prefix/string entry/Map |
    map := entry as Map
    url := map["url"]
    // Old package files don't have a "name" field. In almost cases the
    // name is then the same as the prefix.
    name := (map.get "name") or prefix
    result[url] = name
  return result

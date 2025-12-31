#!/usr/bin/env bats

setup() {
  export GIT_ALLOW_PROTOCOL="file"
}

git_config_identity() {
  local repo="$1"
  git -C "${repo}" config user.email "test@example.com"
  git -C "${repo}" config user.name "Test User"
}

create_sub_repo() {
  local dir="$1"
  local create_parent_branch="${2:-0}" # 1 表示创建 wt/test 分支

  mkdir -p "${dir}"
  git init -q "${dir}"
  git_config_identity "${dir}"
  git -C "${dir}" checkout -qb dev
  echo "sub" > "${dir}/sub.txt"
  git -C "${dir}" add -A
  git -C "${dir}" commit -qm "init sub"

  if [[ "${create_parent_branch}" == "1" ]]; then
    git -C "${dir}" checkout -qb "wt/test"
    echo "branch wt/test" >> "${dir}/sub.txt"
    git -C "${dir}" add -A
    git -C "${dir}" commit -qm "add wt/test"
    git -C "${dir}" checkout -q dev
  fi
}

create_parent_repo_with_submodule() {
  local dir="$1"
  local sub_repo="$2"

  mkdir -p "${dir}"
  git init -q "${dir}"
  git_config_identity "${dir}"
  git -C "${dir}" checkout -qb main
  echo "parent" > "${dir}/parent.txt"
  git -C "${dir}" add -A
  git -C "${dir}" commit -qm "init parent"

  git -C "${dir}" -c protocol.file.allow=always submodule add -q -b dev "${sub_repo}" "libs/sub"
  git -C "${dir}" commit -qam "add submodule"
}

@test "wtide init：父分支不存在时，优先使用 .gitmodules branch" {
  local sub="${BATS_TEST_TMPDIR}/sub1"
  local parent="${BATS_TEST_TMPDIR}/parent1"
  local wt="${BATS_TEST_TMPDIR}/wt1"

  create_sub_repo "${sub}" "0"
  create_parent_repo_with_submodule "${parent}" "${sub}"

  git -C "${parent}" worktree add -q -b "wt/test" "${wt}" main

  run "${BATS_TEST_DIRNAME}/../worktree/wtide.sh" init "${wt}" --no-fetch --no-pull
  [ "$status" -eq 0 ]

  run git -C "${wt}/libs/sub" rev-parse --abbrev-ref HEAD
  [ "$status" -eq 0 ]
  [ "$output" = "dev" ]
}

@test "wtide init：子模块存在与父分支同名分支时，优先切到父分支" {
  local sub="${BATS_TEST_TMPDIR}/sub2"
  local parent="${BATS_TEST_TMPDIR}/parent2"
  local wt="${BATS_TEST_TMPDIR}/wt2"

  create_sub_repo "${sub}" "1"
  create_parent_repo_with_submodule "${parent}" "${sub}"

  git -C "${parent}" worktree add -q -b "wt/test" "${wt}" main

  run "${BATS_TEST_DIRNAME}/../worktree/wtide.sh" init "${wt}" --no-fetch --no-pull
  [ "$status" -eq 0 ]

  run git -C "${wt}/libs/sub" rev-parse --abbrev-ref HEAD
  [ "$status" -eq 0 ]
  [ "$output" = "wt/test" ]
}

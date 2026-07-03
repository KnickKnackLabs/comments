/** @jsxImportSource jsx-md */

import { existsSync, readFileSync, readdirSync, statSync } from "fs";
import { join, resolve } from "path";

import {
  Badge,
  Badges,
  Bold,
  Cell,
  Center,
  Code,
  CodeBlock,
  Details,
  HR,
  Heading,
  Item,
  LineBreak,
  Link,
  List,
  Paragraph,
  Raw,
  Section,
  Sub,
  Table,
  TableHead,
  TableRow,
} from "readme";

const PROJECT = {
  name: "comments",
  oneLine: "Harvest and consume structured directives embedded in source comments.",
  tagline: "Turn comments into explicit, user-triggered commands.",
  license: "MIT",
};

const REPO_DIR = resolve(import.meta.dirname);
const TASK_DIR = join(REPO_DIR, ".mise/tasks");
const TEST_DIR = join(REPO_DIR, "test");
const WORKFLOW = join(REPO_DIR, ".github/workflows/test.yml");

interface TaskInfo {
  name: string;
  description: string;
}

function read(path: string): string {
  return readFileSync(path, "utf8");
}

function walkFiles(dir: string, predicate: (path: string) => boolean): string[] {
  if (!existsSync(dir)) return [];

  const results: string[] = [];
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const full = join(dir, entry.name);
    if (entry.isDirectory()) {
      results.push(...walkFiles(full, predicate));
    } else if (predicate(full)) {
      results.push(full);
    }
  }
  return results;
}

function discoverTasks(dir = TASK_DIR, prefix = ""): TaskInfo[] {
  if (!existsSync(dir)) return [];

  const tasks: TaskInfo[] = [];
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    if (entry.name.startsWith(".")) continue;
    const full = join(dir, entry.name);
    const name = prefix ? `${prefix}:${entry.name}` : entry.name;

    if (entry.isDirectory()) {
      tasks.push(...discoverTasks(full, name));
      continue;
    }

    const mode = statSync(full).mode;
    if ((mode & 0o111) === 0) continue;

    const src = read(full);
    if (/^#MISE hide=true$/m.test(src)) continue;
    const description = src.match(/^#MISE description="(.+)"$/m)?.[1] ?? "";
    tasks.push({ name, description });
  }

  return tasks.sort((a, b) => a.name.localeCompare(b.name));
}

function countBatsTests(): number {
  return walkFiles(TEST_DIR, (path) => path.endsWith(".bats"))
    .map(read)
    .join("\n")
    .match(/@test\s+"/g)?.length ?? 0;
}

function configuredLints(): string[] {
  const miseToml = read(join(REPO_DIR, "mise.toml"));
  const start = miseToml.indexOf("[_.codebase]");
  if (start === -1) return [];

  const lines = miseToml.slice(start).split("\n");
  const block: string[] = [];
  for (const [index, line] of lines.entries()) {
    if (index > 0 && line.startsWith("[")) break;
    block.push(line);
  }

  const list = block.join("\n").match(/lint\s*=\s*\[([\s\S]*?)\]/)?.[1] ?? "";
  return [...list.matchAll(/"([^"]+)"/g)].map((match) => match[1]);
}

function workflowOses(): string[] {
  if (!existsSync(WORKFLOW)) return [];
  const match = read(WORKFLOW).match(/os:\s*\[([^\]]+)\]/);
  if (!match) return [];
  return match[1].split(",").map((os) => os.trim()).filter(Boolean);
}

function status(path: string): string {
  return existsSync(join(REPO_DIR, path)) ? "✓" : "missing";
}

const tasks = discoverTasks();
const testCount = countBatsTests();
const lints = configuredLints();
const oses = workflowOses();

const scaffold = [
  ["mise.toml", "tools, settings, and codebase lint config"],
  ["README.tsx", "programmable README source"],
  ["CONTRIBUTING.md", "repo-entry orientation surface"],
  [".mise/tasks/test", "canonical BATS runner"],
  [".mise/tasks/doctor", "local health check plus hook hint"],
  [".github/workflows/test.yml", "Ubuntu/macOS CI"],
  ["test/", "BATS smoke coverage"],
  ["lib/", "shared runtime code starts here when needed"],
];

const readme = (
  <>
    <Center>
      <Heading level={1}>{PROJECT.name}</Heading>

      <Paragraph>
        <Bold>{PROJECT.oneLine}</Bold>
      </Paragraph>

      <Paragraph>{PROJECT.tagline}</Paragraph>

      <Badges>
        <Badge label="shape" value="mise + BATS" color="4EAA25" logo="gnubash" logoColor="white" />
        <Badge label="tests" value={`${testCount}`} color="brightgreen" href="test/" />
        <Badge label="lints" value={`${lints.length}`} color="blue" />
        <Badge label="README" value="TSX" color="f472b6" />
        <Badge label="License" value={PROJECT.license} color="blue" href="LICENSE" />
      </Badges>
    </Center>

    <LineBreak />

    <Section title="What this is">
      <Paragraph>
        <Code>comments</Code>
        {" is a generic CLI for extracting structured directives from source comments, evaluating them with nushell, and optionally writing results back to disk."}
      </Paragraph>

      <Paragraph>
        {"A directive is a comment body that starts with "}
        <Code>{"<flags>!"}</Code>
        {". "}
        <Code>comments</Code>
        {" extracts those directives, evaluates the body with nushell, and can optionally replace the original comment with command output."}
      </Paragraph>
    </Section>

    <Section title="Install">
      <Paragraph>
        {"After this package is registered with "}
        <Link href="https://github.com/KnickKnackLabs/shiv">shiv</Link>
        {", install it as:"}
      </Paragraph>

      <CodeBlock lang="bash">{`shiv install comments`}</CodeBlock>

      <Paragraph>
        {"Public usage examples assume the shiv-installed command name, "}
        <Code>comments</Code>
        {"."}
      </Paragraph>
    </Section>

    <Section title="Working from a checkout">
      <CodeBlock lang="bash">{`gh repo clone KnickKnackLabs/comments
cd comments

mise trust
mise install
mise run test
mise run doctor

# Run commands through mise while developing from the checkout.
mise run dispatch --stdout examples/basic.md

# Optional local safety net: installs .git/hooks/pre-commit.d/codebase
codebase pre-commit`}</CodeBlock>
    </Section>

    <Section title="Goodies baked in">
      <Table>
        <TableHead>
          <Cell>Goodie</Cell>
          <Cell>Why it exists</Cell>
          <Cell>Where</Cell>
        </TableHead>
        <TableRow>
          <Cell>Generated README</Cell>
          <Cell>TSX can count tests, list tasks, and keep docs honest in CI.</Cell>
          <Cell><Code>README.tsx</Code></Cell>
        </TableRow>
        <TableRow>
          <Cell>Doctor hook check</Cell>
          <Cell>Local pre-commit hooks are clone-local, so the repo can report them without pretending they are tracked.</Cell>
          <Cell><Code>mise run doctor</Code></Cell>
        </TableRow>
        <TableRow>
          <Cell>Convention lints</Cell>
          <Cell>Best-practice drift gets caught as code, not folklore.</Cell>
          <Cell><Code>[_.codebase].lint</Code></Cell>
        </TableRow>
        <TableRow>
          <Cell>Real test path</Cell>
          <Cell>BATS tests call tasks through <Code>mise run</Code>, not raw scripts.</Cell>
          <Cell><Code>test/test_helper.bash</Code></Cell>
        </TableRow>
        <TableRow>
          <Cell>Mac + Linux CI</Cell>
          <Cell>Bash and tooling differences show up before merge.</Cell>
          <Cell>{oses.join(" + ") || "workflow pending"}</Cell>
        </TableRow>
      </Table>
    </Section>

    <Section title="Scaffold inventory">
      <Table>
        <TableHead>
          <Cell>Path</Cell>
          <Cell>Status</Cell>
          <Cell>Purpose</Cell>
        </TableHead>
        {scaffold.map(([path, purpose]) => (
          <TableRow>
            <Cell><Code>{path}</Code></Cell>
            <Cell>{status(path)}</Cell>
            <Cell>{purpose}</Cell>
          </TableRow>
        ))}
      </Table>
    </Section>

    <Section title="Tasks">
      <Table>
        <TableHead>
          <Cell>Task</Cell>
          <Cell>Description</Cell>
        </TableHead>
        {tasks.map((task) => (
          <TableRow>
            <Cell><Code>{`mise run ${task.name}`}</Code></Cell>
            <Cell>{task.description}</Cell>
          </TableRow>
        ))}
      </Table>
    </Section>

    <Section title="Usage">
      <Paragraph>
        {"A directive is a source comment whose normalized body starts with "}
        <Code>!</Code>
        {" or a known flag sequence such as "}
        <Code>o!</Code>
        {" followed by a Nushell script. Prose comments like "}
        <Code>TODO!</Code>
        {" are ignored."}
      </Paragraph>

      <CodeBlock lang="md">{`<!-- !$"run and consume me" -->

<!-- o!$"replace me with stdout" -->

<!--
o!
let rows = [1 2 3]
$rows | length
-->`}</CodeBlock>

      <Paragraph>
        {"Dispatch every directive in a file:"}
      </Paragraph>

      <CodeBlock lang="bash">{`comments dispatch notes.md`}</CodeBlock>

      <Paragraph>
        {"Execute directives and write the transformed file content to stdout instead of saving it to the target file:"}
      </Paragraph>

      <CodeBlock lang="bash">{`comments dispatch --stdout notes.md`}</CodeBlock>

      <Paragraph>
        {"Require all directive comments to succeed before applying comment transformations:"}
      </Paragraph>

      <CodeBlock lang="bash">{`comments dispatch --atomic notes.md`}</CodeBlock>

      <List>
        <Item><Code>!script</Code> runs the script and consumes the directive comment.</Item>
        <Item><Code>o!script</Code> runs the script and replaces the directive comment with stdout.</Item>
        <Item><Code>o</Code> is currently the only supported public flag; recognized but unsupported flags fail without consuming the directive.</Item>
        <Item>Default dispatch is best-effort: failed directives remain unchanged, while successful directives are consumed/replaced.</Item>
        <Item><Code>--atomic</Code> applies no comment transformations if any directive fails or is unsupported.</Item>
        <Item>If a directive mutates the target file during normal dispatch, <Code>comments</Code> refuses to apply stale byte-range replacements.</Item>
        <Item><Code>--stdout</Code> executes directive scripts and emits the transformed file content to stdout instead of saving comment replacements to the target file.</Item>
      </List>
    </Section>

    <Section title="Supported files">
      <Paragraph>
        {"The v1 supported extension set is intentionally explicit: "}
        <Code>.md</Code>
        {", "}
        <Code>.js</Code>
        {", "}
        <Code>.jsx</Code>
        {", "}
        <Code>.ts</Code>
        {", "}
        <Code>.tsx</Code>
        {", "}
        <Code>.rs</Code>
        {", "}
        <Code>.go</Code>
        {", "}
        <Code>.sh</Code>
        {", and "}
        <Code>.py</Code>
        {". Unsupported extensions fail clearly instead of being treated as files with no directives."}
      </Paragraph>
    </Section>

    <Section title="Context">
      <Paragraph>
        {"Each directive script receives a structured "}
        <Code>$context</Code>
        {" record:"}
      </Paragraph>

      <CodeBlock lang="nu">{`$context.file                  # absolute target file path
$context.target_dir            # parent directory of the target file
$context.caller_pwd            # COMMENTS_CALLER_PWD, or the dispatch cwd fallback
$context.lines                 # original file lines
$context.directive.flags       # flag string, e.g. "o"
$context.directive.flag_list   # flag list, e.g. ["o"]
$context.directive.range       # ast-grep byte/line range
$context.directive.text        # original comment text
$context.directive.body        # normalized comment body
$context.directive.script      # script being executed`}</CodeBlock>
    </Section>

    <Section title="Examples">
      <List>
        <Item><Code>examples/basic.md</Code> shows consume-only directives, output replacement, and multiline directive form.</Item>
        <Item><Code>examples/chat.md</Code> is a recipe for sending a file-local note through the <Code>chat</Code> CLI; it is not a live directive because <Code>chat send</Code> has side effects.</Item>
      </List>
    </Section>

    <Section title="Design notes">
      <List ordered>
        <Item>Use ast-grep/tree-sitter to extract comment-like nodes where possible.</Item>
        <Item>Recognize directives whose normalized comment body starts with <Code>{"<flags>!"}</Code>.</Item>
        <Item>Evaluate directive bodies with nushell; context is opt-in and available at consumption time.</Item>
        <Item>Keep the core independent of any one editor or calling workflow.</Item>
        <Item>Write results by editing files on disk; do not require editor buffer access.</Item>
      </List>
    </Section>

    <Details summary="Current convention checks">
      <Paragraph>
        {"This template currently asks "}
        <Link href="https://github.com/KnickKnackLabs/codebase">codebase</Link>
        {" to run these lint rules:"}
      </Paragraph>
      <CodeBlock>{lints.join("\n")}</CodeBlock>
    </Details>

    <Section title="Validation">
      <CodeBlock lang="bash">{`mise run test
codebase lint "$PWD"
readme build --check
git diff --check`}</CodeBlock>

      <Paragraph>
        {"The starter suite currently has "}
        <Bold>{`${testCount} tests`}</Bold>
        {" and "}
        <Bold>{`${tasks.length} public tasks`}</Bold>
        {". Those numbers are read from the repo at README build time."}
      </Paragraph>
    </Section>

    <Center>
      <HR />
      <Sub>
        {"This README was generated from "}
        <Code>README.tsx</Code>
        {" with "}
        <Link href="https://github.com/KnickKnackLabs/readme">KnickKnackLabs/readme</Link>
        {"."}
        <Raw>{"<br />"}</Raw>
        {"Comments are executable only when a human chooses to consume them."}
      </Sub>
    </Center>
  </>
);

console.log(readme);

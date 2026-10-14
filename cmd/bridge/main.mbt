///|
extern "js" fn input() -> String =
  #|() => globalThis.__moonwellInput

///|
extern "js" fn output(text : String) -> Unit =
  #|(text) => { process.stdout.write(text + "\n"); }

///|
fn main {
  output(@well.execute(input()))
}

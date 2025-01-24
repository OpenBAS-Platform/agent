#[cfg(test)]
mod tests {
    use crate::process::agent_exec::command_execution;
    use std::env;
    use std::fs;
    use std::panic;

    const TEST_AGENT_ID: &str = &"62e1e7a6-79af-47ae-ac4a-8324c2b82197";
    const CLEANUP_ENABLED: bool = true;

    fn cleanup_after_tests() {
        if CLEANUP_ENABLED {
            let current_exe_patch = env::current_exe().unwrap();
            let executable_path = current_exe_patch.parent().unwrap();
            let path = executable_path.join(format!("execution-{}", TEST_AGENT_ID));
            let _ = fs::remove_dir_all(path);
        }
    }

    #[test]
    fn test_simple_execution_no_panic() {
        let result = panic::catch_unwind(|| {
            return command_execution(TEST_AGENT_ID, &"echo 'Hello World'");
        });
        cleanup_after_tests();
        assert!(result.unwrap().is_ok());
    }
}

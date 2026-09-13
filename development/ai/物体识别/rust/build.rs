use std::env;
use std::fs;

fn link_dylib(so_path: &str) {
    let so_dir = fs::canonicalize(so_path).expect("so file not found");
    let src_dir = so_dir.parent().unwrap();
    let so_file = so_dir.file_name().unwrap().to_str().unwrap();

    println!("cargo:rustc-link-search={}", src_dir.display());
    println!("cargo:rustc-link-arg=-l:{so_file}");
    println!("cargo:rustc-link-arg=-Wl,-rpath,$ORIGIN/lib");
}

fn main() {
    let target = env::var("TARGET").unwrap_or_default();

    if target.contains("aarch64") {
        link_dylib("../rknn/rknn_lib/build/libdetect.so");
    }
}
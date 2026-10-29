use clap::Parser;

/// autotiling for sway
#[derive(Debug, Parser)]
pub struct Args {
    /// limit splitting
    #[arg(long, default_value_t = 0)]
    pub limit: usize,

    /// vertical split factor
    #[arg(long, default_value_t = 1.0, value_parser = positive_float)]
    pub splitwidth: f64,

    /// horizontal split factor
    #[arg(long, default_value_t = 1.0, value_parser = positive_float)]
    pub splitheight: f64,

    /// split direction ratio
    #[arg(long, default_value_t = 1.0, value_parser = positive_float)]
    pub splitratio: f64,

    /// swap the focused window with the largest tiling window
    #[arg(long)]
    pub focus_to_master: bool,
}

fn positive_float(value: &str) -> Result<f64, String> {
    let value: f64 = value
        .parse()
        .map_err(|_| format!("'{value}' is not a number"))?;
    if value > 0.0 && value.is_finite() {
        Ok(value)
    } else {
        Err("must be a positive number".to_string())
    }
}

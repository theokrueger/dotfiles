use swayipc::{Connection, Fallible, Node, NodeLayout, NodeType};

use crate::{
    args::Args,
    tree::{depth_limit_reached, find_focused, path_to},
};

fn resize_new_container(connection: &mut Connection, con: &Node, parent: &Node, args: &Args) {
    let Some(percent) = con.percent.filter(|percent| *percent != 0.0) else {
        return;
    };

    let (dimension, size) = match parent.layout {
        NodeLayout::SplitV if args.splitheight != 1.0 => {
            ("height", (percent * args.splitheight * 100.0) as i64)
        }
        NodeLayout::SplitH if args.splitwidth != 1.0 => {
            ("width", (percent * args.splitwidth * 100.0) as i64)
        }
        _ => return,
    };

    let _ = connection.run_command(format!("resize set {dimension} {size} ppt"));
}

fn choose_layout(height: i32, width: i32, splitratio: f64) -> NodeLayout {
    if f64::from(height) > f64::from(width) / splitratio {
        NodeLayout::SplitV
    } else {
        NodeLayout::SplitH
    }
}

fn tiling_target<'a>(tree: &'a Node, args: &Args) -> Option<(&'a Node, &'a Node)> {
    let con = find_focused(tree)?;
    let path = path_to(tree, con.id)?;
    let parent = path.len().checked_sub(2).map(|index| path[index])?;

    let skip = con.node_type == NodeType::FloatingCon
        || depth_limit_reached(&path, args.limit)
        || matches!(parent.layout, NodeLayout::Stacked | NodeLayout::Tabbed)
        || con.fullscreen_mode.unwrap_or(0) != 0;

    (!skip).then_some((con, parent))
}

pub fn autotile(connection: &mut Connection, is_new_or_moved: bool, args: &Args) -> Fallible<()> {
    let tree = connection.get_tree()?;

    let Some((con, parent)) = tiling_target(&tree, args) else {
        return Ok(());
    };

    let new_layout = choose_layout(con.rect.height, con.rect.width, args.splitratio);
    if parent.layout != new_layout {
        let command = match new_layout {
            NodeLayout::SplitV => "splitv",
            _ => "splith",
        };
        connection.run_command(command)?;
    }

    if is_new_or_moved {
        resize_new_container(connection, con, parent, args);
    }

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn splits_correctly() {
        assert_eq!(choose_layout(100, 50, 1.0), NodeLayout::SplitV);
        assert_eq!(choose_layout(50, 100, 1.0), NodeLayout::SplitH);
        assert_eq!(choose_layout(100, 100, 1.0), NodeLayout::SplitH);
        assert_eq!(choose_layout(80, 100, 1.61), NodeLayout::SplitV);
        assert_eq!(choose_layout(60, 100, 1.61), NodeLayout::SplitH);
    }
}

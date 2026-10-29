use swayipc::{Connection, Fallible, Node, NodeType};

use crate::tree::{find_focused, path_to};

pub fn focus_to_master() -> Fallible<()> {
    let mut connection = Connection::new()?;
    let tree = connection.get_tree()?;

    let Some((_, master)) = focused_and_master(&tree) else {
        return Ok(());
    };

    let command = format!("swap container with con_id {}", master.id);
    for result in connection.run_command(command)? {
        result?;
    }

    Ok(())
}

fn focused_and_master(tree: &Node) -> Option<(&Node, &Node)> {
    let con = find_focused(tree)?;
    if !is_view(con) {
        return None;
    }

    let path = path_to(tree, con.id)?;
    let workspace = path
        .iter()
        .rev()
        .find(|node| node.node_type == NodeType::Workspace)?;
    let master = biggest_tiling(workspace, con.id)?;

    (area(con) < area(master)).then_some((con, master))
}

fn biggest_tiling(workspace: &Node, exclude: i64) -> Option<&Node> {
    let mut biggest = None;
    let mut stack = vec![workspace];

    while let Some(node) = stack.pop() {
        if node.id != exclude && is_view(node) && biggest.is_none_or(|best| area(node) > area(best))
        {
            biggest = Some(node);
        }
        stack.extend(node.nodes.iter());
    }

    biggest
}

fn is_view(node: &Node) -> bool {
    node.node_type == NodeType::Con
        && node.nodes.is_empty()
        && node.floating_nodes.is_empty()
        && (node.app_id.is_some() || node.window.is_some() || node.pid.is_some())
}

fn area(node: &Node) -> i64 {
    i64::from(node.rect.width) * i64::from(node.rect.height)
}

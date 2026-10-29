use std::collections::VecDeque;

use swayipc::{Node, NodeType};

pub fn find_focused(root: &Node) -> Option<&Node> {
    let mut queue: VecDeque<&Node> = VecDeque::new();
    queue.extend(root.nodes.iter().chain(root.floating_nodes.iter()));

    while let Some(node) = queue.pop_front() {
        if node.focused {
            return Some(node);
        }
        queue.extend(node.nodes.iter().chain(node.floating_nodes.iter()));
    }

    None
}

pub fn path_to(node: &Node, id: i64) -> Option<Vec<&Node>> {
    if node.id == id {
        return Some(vec![node]);
    }
    for child in node.nodes.iter().chain(node.floating_nodes.iter()) {
        if let Some(mut path) = path_to(child, id) {
            path.insert(0, node);
            return Some(path);
        }
    }
    None
}

pub fn depth_limit_reached(path: &[&Node], limit: usize) -> bool {
    if limit == 0 {
        return false;
    }

    let mut reached = true;
    let mut index = path.len().saturating_sub(1);
    let mut depth: usize = 0;

    while depth < limit {
        if path[index].node_type == NodeType::Workspace {
            reached = false;
            break;
        }
        if index == 0 {
            break;
        }
        index -= 1;
        if path[index].nodes.len() > 1 {
            depth += 1;
        }
    }

    reached
}

use collection::shard::ShardId;
use collection::PeerId;
use serde::{Deserialize, Serialize};

#[derive(Debug, Deserialize, Serialize, PartialEq, Eq, Hash)]
pub struct ShardDistributionProposal {
    distribution: Vec<(ShardId, PeerId)>,
}

impl ShardDistributionProposal {
    pub fn build(shard_number: u32, known_peers: &Vec<PeerId>) -> Self {
        // TODO better distribution scheme that looks at the least occupied peers first
        let mut distribution: Vec<(ShardId, PeerId)> = Vec::with_capacity(shard_number as usize);
        let known_peer_len = known_peers.len();
        for shard_id in 0..shard_number {
            let peer_index = (shard_id as usize).rem_euclid(known_peer_len);
            let selected_peer = known_peers.get(peer_index);
            distribution.push((shard_id, *selected_peer.unwrap()));
        }
        Self { distribution }
    }

    pub fn shards_for_peer(&self, peer_id: PeerId) -> Vec<ShardId> {
        self.distribution
            .iter()
            .filter_map(
                |(shard, peer)| {
                    if peer == &peer_id {
                        Some(*shard)
                    } else {
                        None
                    }
                },
            )
            .collect()
    }
}

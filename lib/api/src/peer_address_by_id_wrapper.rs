use itertools::Itertools;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use tonic::codegen::http;
use tonic::transport::Uri;

/// Workaround until we can get rid of the wrapper using https://serde.rs/remote-derive.html.
/// The PeerAddressByIdWrapper needs to be visible by storage and collection

pub type PeerAddressById = HashMap<u64, Uri>;

/// Serializable [`PeerAddressById`]
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
#[serde(try_from = "HashMap<u64, String>")]
#[serde(into = "HashMap<u64, String>")]
pub struct PeerAddressByIdWrapper(pub PeerAddressById);

impl From<PeerAddressByIdWrapper> for HashMap<u64, String> {
    fn from(wrapper: PeerAddressByIdWrapper) -> Self {
        wrapper
            .0
            .into_iter()
            .map(|(id, address)| (id, format!("{address}")))
            .collect()
    }
}

impl TryFrom<HashMap<u64, String>> for PeerAddressByIdWrapper {
    type Error = http::uri::InvalidUri;

    fn try_from(value: HashMap<u64, String>) -> Result<Self, Self::Error> {
        Ok(PeerAddressByIdWrapper(
            value
                .into_iter()
                .map(|(id, address)| address.parse().map(|address| (id, address)))
                .try_collect()?,
        ))
    }
}

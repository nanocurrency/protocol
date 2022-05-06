# ----------------------------------------------------------------------
# Nano protocol definition for Kaitai
# https://github.com/nanocurrency/protocol
# ----------------------------------------------------------------------
meta:
  id: nano
  title: Nano Network Protocol
  license: BSD 2-Clause
  endian: le
seq:
  - id: header
    doc: Message header with message type, version information and message-specific extension bits.
    type: message_header
  - id: body
    doc: Message body whose content depends on block type in the header.
    type:
      switch-on: header.message_type
      cases:
        'enum_msgtype::keepalive': msg_keepalive
        'enum_msgtype::publish': msg_publish
        'enum_msgtype::confirm_req': msg_confirm_req
        'enum_msgtype::confirm_ack': msg_confirm_ack
        'enum_msgtype::bulk_pull': msg_bulk_pull
        'enum_msgtype::bulk_push': msg_bulk_push
        'enum_msgtype::frontier_req': msg_frontier_req
        'enum_msgtype::node_id_handshake': msg_node_id_handshake
        'enum_msgtype::bulk_pull_account': msg_bulk_pull_account
        'enum_msgtype::telemetry_req': msg_telemetry_req
        'enum_msgtype::telemetry_ack': msg_telemetry_ack
        _: ignore_until_eof
instances:
  const_block_zero:
    size: 32
    contents: [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
enums:
  # The protocol version covered by this specification
  protocol_version:
    18: value
  enum_blocktype:
    0x00: invalid
    0x01: not_a_block
    0x02: send
    0x03: receive
    0x04: open
    0x05: change
    0x06: state
  enum_msgtype:
    0x00: invalid
    0x01: not_a_type
    0x02: keepalive
    0x03: publish
    0x04: confirm_req
    0x05: confirm_ack
    0x06: bulk_pull
    0x07: bulk_push
    0x08: frontier_req
    0x0a: node_id_handshake
    0x0b: bulk_pull_account
    0x0c: telemetry_req
    0x0d: telemetry_ack
  enum_bulk_pull_account:
    0x00: pending_hash_and_amount
    0x01: pending_address_only
    0x02: pending_hash_amount_and_address
  enum_network:
    0x41: network_test
    0x42: network_beta
    0x43: network_live

types:

  # -------------------------------------------------------------------
  # Common header for udp and tcp messages
  # -------------------------------------------------------------------  
  message_header:
    seq:
      - id: magic
        contents: R
        doc: Protocol identifier. Always 'R'.
      - id: network_id
        type: u1
        enum: enum_network
        doc: Network ID 'A', 'B' or 'C' for test, beta or live network respectively.
      - id: version_max
        type: u1
        doc: Maximum version supported by the sending node
      - id: version_using
        type: u1
        doc: Version used by the sending node
      - id: version_min
        type: u1
        doc: Minimum version supported by the sending node
      - id: message_type
        type: u1
        enum: enum_msgtype
        doc: Message type
      - id: extensions
        type: u2le
        doc: Extensions bitfield
    instances:
      item_count_int:
        value: (extensions & 0xf000) >> 12
        doc: |
          Since protocol v17. For confirm_ack vote-by-hash, this is the number of hashes
          in the body. For confirm_req request-by-hash, this is the number of hash+root pairs.
      block_type_int:
        value: (extensions & 0x0f00) >> 8
      block_type:
        value: (extensions & 0x0f00) >> 8
        enum: 'enum_blocktype'
        doc: |
          The block type determines what block is embedded in the message.
          For some message types, block type is not relevant and the block type
          is set to "invalid" or "not_a_block"
      query_flag:
        value: (extensions & 0x0001)
        doc: |
          If set, this is a node_id_handshake query. This maybe be set at the
          same time as the response_flag.
      response_flag:
        value: (extensions & 0x0002)
        doc: |
          If set, this is a node_id_handshake response. This maybe be set at the
          same time as the query_flag.
      extended_params_present:
        value: (extensions & 0x0001)
        doc: |
          Since protocol version 15.
          May be set for "bulk_pull" messages.
          If set, the bulk_pull message contain extended parameters.
      telemetry_size:
        value: (extensions & 0x3ff)
        doc: |
          Since protocol version 18.
          Must be set for "telemetry_ack" messages. Indicates size of payload.
      confirmed_present:
        value: (extensions & 0x0002)
        doc: |
          Since protocol version 18 (release 21.3).
          May be set for "frontier_req" messages.
          If set, the frontier_req response contains confirmed frontiers for each account.
      ascending_present:
        value: (extensions & 0x0002)
        doc: |
          Since protocol version 18.
          May be set for "bulk_pull" messages.
          If set, server will respond with succesor blocks.

  # Catch-all that ignores until eof
  ignore_until_eof:
    seq:
      - id: empty
        type: u1
        repeat: until
        repeat-until: _io.eof
        if: not _io.eof

  # -------------------------------------------------------------------
  # Block definitions
  # -------------------------------------------------------------------

  block_send:
    seq:
     - id: previous
       size: 32
       doc: Hash of the previous block
     - id: destination
       size: 32
       doc: Public key of destination account
     - id: balance
       size: 16
       doc: 128-bit big endian balance
     - id: signature
       size: 64
       doc: ed25519-blake2b signature
     - id: work
       type: u8le
       doc: Proof of work

  block_receive:
    seq:
     - id: previous
       size: 32
       doc: Hash of the previous block
     - id: source
       size: 32
       doc: Hash of the source send block
     - id: signature
       size: 64
       doc: ed25519-blake2b signature
     - id: work
       type: u8le
       doc: Proof of work

  block_open:
    seq:
     - id: source
       size: 32
       doc: Hash of the source send block
     - id: representative
       size: 32
       doc: Public key of initial representative account
     - id: account
       size: 32
       doc: Public key of account being opened
     - id: signature
       size: 64
       doc: ed25519-blake2b signature
     - id: work
       type: u8le
       doc: Proof of work

  block_change:
    seq:
     - id: previous
       size: 32
       doc: Hash of the previous block
     - id: representative
       size: 32
       doc: Public key of new representative account
     - id: signature
       size: 64
       doc: ed25519-blake2b signature
     - id: work
       type: u8le
       doc: Proof of work

  block_state:
    seq:
     - id: account
       size: 32
       doc: Public key of account represented by this state block
     - id: previous
       size: 32
       doc: Hash of previous block
     - id: representative
       size: 32
       doc: Public key of the representative account
     - id: balance
       size: 16
       doc: 128-bit big endian balance
     - id: link
       size: 32
       doc: Pairing send's block hash (open/receive), 0 (change) or destination public key (send)
     - id: signature
       size: 64
       doc: ed25519-blake2b signature
     - id: work
       type: u8be
       doc: Proof of work (big endian)
    doc: State block

  # The block selector takes an integer argument representing the
  # block type. This setup makes it possible to reuse the selector
  # both when deserializing block types as well as when extracting the
  # block type from the header extensions.
  # Note that enum arguments are not yet supported, hence the to_i casts.
  block_selector:
    doc: Selects a block based on the argument
    params:
      - id: arg_block_type
        type: u1
    seq:
      - id: block
        type:
          switch-on: arg_block_type
          cases:
            'enum_blocktype::send.to_i': block_send
            'enum_blocktype::receive.to_i': block_receive
            'enum_blocktype::open.to_i': block_open
            'enum_blocktype::change.to_i': block_change
            'enum_blocktype::state.to_i': block_state
            _: ignore_until_eof

  # --------------------------------------------------------------------
  # LIVE MESSAGES
  # --------------------------------------------------------------------

  peer:
    doc: A peer entry in the keepalive message
    seq:
      - id: address
        size: 16
        doc: ipv6 address, or ipv6-mapped ipv4 address.
      - id: port
        type: u2le
        doc: Port number. Default port is 7075.

  msg_keepalive:
    doc: A list of 8 peers, some of which may be all-zero.
    seq:
      - id: peers
        type: peer
        repeat: until
        repeat-until: _index == 8 or _io.eof
        if: not _io.eof

  vote_common:
    doc: Common data shared by block votes and vote-by-hash votes
    seq:
      - id: account
        size: 32
      - id: signature
        size: 64
      - id: timestamp_and_vote_duration
        type: u8le
    instances:
        timestamp:
          value: (timestamp_and_vote_duration & 0xfffffffffffffff0)
          doc: Number of seconds since the UTC epoch vote was generated at
        vote_duration_bits:
          value: (timestamp_and_vote_duration & 0xf)
          doc: Since V23.0 this is specified as 2^(duration + 4) in milliseconds

  vote_by_hash:
    doc: A sequence of hashes, where count is read from header.
    seq:
      - id: hashes
        size: 32
        repeat: until
        repeat-until: _index == _root.header.item_count_int or _io.eof
        if: not _io.eof

  hash_pair:
    doc: A general purpose pair of 32-byte hash values
    seq:
      - id: first
        size: 32
        doc: First hash in pair
      - id: second
        size: 32
        doc: Second hash in pair

  confirm_request_by_hash:
    doc: A sequence of hash,root pairs
    seq:
      - id: pairs
        doc: Up to "count" pairs of hash (first) and root (second), where count is read from header.
        type: hash_pair
        repeat: until
        repeat-until: _index == _root.header.item_count_int or _io.eof
        if: not _io.eof

  msg_confirm_req:
    doc: Requests confirmation of the given block or list of root/hash pairs
    seq:
      - id: reqbyhash
        if: _root.header.block_type == enum_blocktype::not_a_block
        type: confirm_request_by_hash
      - id: block
        if: _root.header.block_type != enum_blocktype::not_a_block
        type: block_selector(_root.header.block_type_int)

  msg_confirm_ack:
    doc: Signed confirmation of a block or a list of block hashes
    seq:
      - id: common
        type: vote_common
      - id: votebyhash
        if: _root.header.block_type == enum_blocktype::not_a_block
        type: vote_by_hash
      - id: block
        if: _root.header.block_type != enum_blocktype::not_a_block
        type: block_selector(_root.header.block_type_int)

  msg_telemetry_req:
    doc: Request node telemetry metrics

  msg_telemetry_ack:
    doc: Signed telemetry response
    seq:
      - id: signature
        size: 64
        doc: Signature (Big endian)
      - id: nodeid
        size: 32
        doc: Public node id (Big endian)
      - id: blockcount
        type: u8be
        doc: Block count
      - id: cementedcount
        type: u8be
        doc: Cemented block count
      - id: uncheckedcount
        type: u8be
        doc: Unchecked block count
      - id: accountcount
        type: u8be
        doc: Account count
      - id: bandwidthcap
        type: u8be
        doc: Bandwidth limit, 0 indiciates unlimited
      - id: peercount
        type: u4be
        doc: Peer count
      - id: protocolversion
        type: u1
        doc: Protocol version
      - id: uptime
        type: u8be
        doc: Length of time a peer has been running for (in seconds)
      - id: genesisblock
        size: 32
        doc: Genesis block hash (Big endian)
      - id: majorversion
        type: u1
        doc: Major version
      - id: minorversion
        type: u1
        doc: Minor version
      - id: patchversion
        type: u1
        doc: Patch version
      - id: prereleaseversion
        type: u1
        doc: Pre-release version
      - id: maker
        type: u1
        doc: Maker version. 0 indicates it is from the Nano Foundation, there is no standardised list yet for any others.
      - id: timestamp
        type: u8be
        doc: Number of milliseconds since the UTC epoch
      - id: activedifficulty
        type: u8be
        doc: The current network active difficulty.
      - id: unknown_data
        type: u8
        repeat: until
        repeat-until: _io.pos == _root.header.telemetry_size
        if: _io.pos < _root.header.telemetry_size

  msg_publish:
    doc: Publish the given block
    seq:
      - id: body
        type: block_selector(_root.header.block_type_int)

  # Note that graphviz will display query/response as consecutive entries
  # since they can both be present at the same time.
  msg_node_id_handshake:
    doc: A node ID handshake request and/or response.
    seq:
      - id: query
        if: _root.header.query_flag != 0
        type: node_id_query        
      - id: response
        if: _root.header.response_flag != 0
        type: node_id_response

  node_id_query:
    seq:
      - id: cookie
        size: 32
        doc: Per-endpoint random number

  node_id_response:
    seq:
      - id: account
        size: 32
        doc: Account (node id)
      - id: signature
        size: 64
        doc: Signature

  # --------------------------------------------------------------------
  # BOOTSTRAP MESSAGES
  # --------------------------------------------------------------------

  msg_bulk_pull_account:
    doc: Bulk pull account request.
    seq:
      - id: account
        size: 32
        doc: Account public key.
      - id: minimum_amount
        size: 16
        doc: 128-bit big endian minimum amount.
      - id: flags
        type: u1
        enum: enum_bulk_pull_account
  
  bulk_pull_account_response:
    doc: |
      Response of the msg_bulk_pull_account message. The structure depends on the 
      flags that was passed to the query.
    params:
      - id: flags
        type: u1
    seq:
      - id: frontier_entry
        type: frontier_balance_entry
      - id: pending_entry
        type: bulk_pull_account_entry(flags)
        repeat: until
        repeat-until: _io.eof or pending_entry[_index].hash == _root.const_block_zero
    types:
      frontier_balance_entry:
        seq:
          - id: frontier_hash
            size: 32
            doc: Hash of the head block of the account chain.
          - id: balance
            size: 16
            doc: 128-bit big endian account balance.
      bulk_pull_account_entry:
        params:
          - id: flags
            type: u1
        instances:
          pending_address_only:
            value: flags == enum_bulk_pull_account::pending_address_only.to_i
          pending_include_address:
            value: flags == enum_bulk_pull_account::pending_hash_amount_and_address.to_i
        seq:
          - id: hash
            size: 32
            if: not pending_address_only
          - id: amount
            size: 16
            if: not pending_address_only
          - id: source
            size: 32
            if: pending_address_only or pending_include_address
            
  msg_bulk_pull:
    doc: Bulk pull request.
    seq:
      - id: start
        size: 32
        doc: Account public key or block hash.
      - id: end
        size: 32
        doc: End block hash. May be zero.
      - id: extended
        type: extended_parameters
        if: _root.header.extended_params_present != 0
    types:
      extended_parameters:
        seq:
          - id: zero
            type: u1
            doc: Must be 0
          - id: count
            type: u4le
            doc: little endian "count" parameter to limit the response set.
          - id: reserved
            size: 3
            doc: Reserved extended parameter bytes

  bulk_pull_response:
    doc: Response of the msg_bulk_pull request.
    seq:
      - id: entry
        type: bulk_pull_entry
        repeat: until
        repeat-until: _io.eof or entry[_index].block_type == enum_blocktype::not_a_block.to_i
    types:
      bulk_pull_entry:
        seq:
          - id: block_type
            type: u1
          - id: block
            type: block_selector(block_type)

  msg_bulk_push:
    doc: |
      A bulk push is equivalent to an unsolicited bulk pull response.
      If a node knows about an account a peer doesn't, the node sends
      its local blocks for that account to the peer. The stream of
      blocks ends with a sentinel block of type enum_blocktype::not_a_block.
    seq:
      - id: entry
        type: bulk_push_entry
        repeat: until
        repeat-until: _io.eof or entry[_index].block_type == enum_blocktype::not_a_block.to_i
    types:
      bulk_push_entry:
        seq:
          - id: block_type
            type: u1
          - id: block
            type: block_selector(block_type)

  bulk_push_response:
    doc: The msg_bulk_push request does not have a response.

  msg_frontier_req:
    doc: Request frontiers (account chain head blocks) from a remote node
    seq:
      - id: start
        size: 32
        doc: Public key of start account
      - id: age
        type: u4le
        doc: Maximum age of included account. If 0xffffffff, turn off age filtering.
      - id: count
        type: u4le
        doc: Maximum number of accounts to include. If 0xffffffff, turn off count limiting.

  frontier_response:
    doc: |
      Response of the msg_frontier_req TCP request. An all-zero account and frontier_hash signifies the end of the result.
    seq:
      - id: entry
        type: frontier_entry
        repeat: until
        repeat-until: _io.eof or entry[_index].frontier_hash == _root.const_block_zero
    types:
      frontier_entry:
        seq:
          - id: account
            size: 32
            doc: Public key of account.
          - id: frontier_hash
            size: 32
            doc: Hash of the head block of the account chain.

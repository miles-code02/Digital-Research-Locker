# Digital Research Locker Smart Contract

A blockchain-based system for storing and managing academic records, research papers, and portfolios.

## Features

- Secure document hash storage
- Access control management
- Public/private document settings
- Student identity linkage
- Document verification via blockchain

## Contract Functions

### Public Functions

- `store-document` - Store a document hash on blockchain
- `grant-access` - Grant access to specific users
- `revoke-access` - Revoke previously granted access
- `update-visibility` - Change document public/private status

### Read-Only Functions

- `get-document` - Get document metadata
- `has-access` - Check if a user has access
- `get-user-document-count` - Get document count for user
- `get-document-nonce` - Get current document counter

## Usage

Deploy with Clarinet to enable secure academic record management.
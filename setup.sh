#! /bin/bash
set -e

cp .env.template .dev.vars

# Must be on wrangler 3.72.3 or later, otherwise the create command will create V1 indexes, not V2
npx wrangler vectorize create cloudflare-rag-index --dimensions=1024 --metric=euclidean
# Must be on wrangler 3.72.3 or later
npx wrangler vectorize create-metadata-index cloudflare-rag-index --property-name=session_id --type=string

npx wrangler r2 bucket create cloudflare-rag-bucket

# Step 1: Run the wrangler command and capture the database_id
output=$(npx wrangler d1 create cloudflare-rag)
# Extract the new database_id from the output using grep and cut
new_database_id=$(echo "$output" | grep "database_id =" | cut -d '"' -f 2)
# Step 2: Replace the old database_id in the wrangler.toml file
sed -i '' "s/database_id = \".*\"/database_id = \"$new_database_id\"/" wrangler.toml
echo "Updated wrangler.toml with new database_id: $new_database_id"

# Step 3: Create the KV namespace and capture the id
kv_output=$(npx wrangler kv namespace create rate-limiter)
new_kv_id=$(echo "$kv_output" | grep "id =" | awk -F '"' '{print $2}')
# Step 4: Replace the old KV id in the wrangler.toml file for the rate_limiter binding
sed -i '' "/\[\[kv_namespaces\]\]/,/^\[/{
  /binding = \"rate_limiter\"/{
    n
    s/id = \".*\"/id = \"$new_kv_id\"/
  }
}" wrangler.toml
echo "Updated wrangler.toml with new KV id for rate_limiter: $new_kv_id"
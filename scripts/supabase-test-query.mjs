import "dotenv/config";
import { createClient } from "@supabase/supabase-js";

const url = process.env.SUPABASE_URL;
const anonKey = process.env.SUPABASE_ANON_KEY;
const table = process.env.SUPABASE_TEST_TABLE || "riddles";

if (!url || !anonKey) {
  console.error("Missing SUPABASE_URL or SUPABASE_ANON_KEY.");
  process.exit(1);
}

const supabase = createClient(url, anonKey, {
  auth: {
    persistSession: false,
    autoRefreshToken: false
  }
});

async function run() {
  const { data, error, count } = await supabase
    .from(table)
    .select("*", { count: "exact", head: true })
    .limit(1);

  if (error) {
    console.error("Supabase query failed:", error.message);
    console.error("Table tested:", table);
    console.error("Tip: set SUPABASE_TEST_TABLE to a table available to your anon key.");
    process.exit(1);
  }

  console.log("Supabase connection and query succeeded.");
  console.log("Table tested:", table);
  console.log("Approx row count:", count ?? "unknown");
  console.log("Returned rows in head mode:", Array.isArray(data) ? data.length : 0);
}

run().catch((err) => {
  console.error("Unexpected failure:", err);
  process.exit(1);
});

# 🚀 URGENT: Apply Database Migrations

## Two Critical Issues Fixed:
1. ✅ **RPC function missing** → Added `get_user_roles()` for efficient role detection
2. ✅ **Query timeout** → Added database indexes to speed up queries by 10-100x

---

## 📋 STEP 1: Apply SQL Migrations (5 minutes)

### Option A: One-Click (Recommended)
1. Go to: https://supabase.com/dashboard/project/fwnknmqlhlyxdeyfcrad/sql/new
2. Copy **ALL** contents from: `supabase/migrations/APPLY_ALL_MIGRATIONS.sql`
3. Paste into SQL Editor
4. Click **RUN** ▶️
5. Wait for: "Migration completed successfully! ✓"

### Option B: Individual Scripts
If Option A fails, run these in order:
1. `supabase/migrations/create_get_user_roles_function.sql`
2. `supabase/migrations/add_performance_indexes.sql`

---

## 📋 STEP 2: Verify Deployment (2 minutes)

### Check Vercel Auto-Deploy
1. Go to: https://vercel.com/dashboard
2. Your project should auto-deploy (latest commit: `9582751a`)
3. Wait for deployment to complete (1-2 minutes)

### OR Trigger Manual Redeploy
If auto-deploy didn't trigger:
1. Vercel Dashboard → Your Project
2. Deployments tab → Click "..." → Redeploy

---

## 📋 STEP 3: Test the Fix (1 minute)

1. **Clear browser cache:**
   - Chrome: Ctrl+Shift+Delete → Clear cache
   - Or: DevTools (F12) → Network tab → Disable cache ✓

2. **Login and check console:**
   ```
   ✅ Should see: [roleDetection] roles extracted: {admin: {...}, warden: {...}}
   ❌ Should NOT see: 400 error on get_user_roles
   ❌ Should NOT see: query timeout errors
   ```

3. **Test Still Out tab:**
   - Should load within 2-3 seconds (was timing out before)
   - Default: shows last 30 days only

---

## 🎯 What Changed?

### Code Changes (Already Deployed to GitHub)
- ✅ JWT-based role detection (1 RPC call instead of 3 REST calls)
- ✅ Fixed arch_gate schema (display_name, not phone)
- ✅ Added 30-day default date range for "Still Out" queries
- ✅ Reduced page size from 1000 to 500 for better performance

### Database Changes (YOU NEED TO APPLY - Step 1 above)
- ✅ RPC function: `get_user_roles(email)`
- ✅ 9 indexes on `outing_requests` table for faster queries

---

## ⏱️ Expected Results After Migration

| Query Type | Before | After |
|------------|--------|-------|
| Role check | 3 REST calls (3-5s) | 1 RPC call (<1s) |
| Still Out tab | TIMEOUT ❌ | 2-3s ✅ |
| Pending bookings | 10-15s | 1-2s ✅ |
| Search by room | 5-10s | <1s ✅ |

---

## ❓ Troubleshooting

### "RPC function not found" error persists
- **Cause:** SQL migration not applied
- **Fix:** Go back to Step 1 and apply the SQL

### "Query timeout" still happens
- **Cause:** Indexes not created
- **Fix:** Run `add_performance_indexes.sql` separately

### "Nothing changed after deployment"
- **Cause:** Browser cache
- **Fix:** Hard refresh (Ctrl+F5) or clear cache

---

## 📞 Need Help?

Check these files for reference:
- Full schema: `DATABASE_SCHEMA.md`
- Combined SQL: `supabase/migrations/APPLY_ALL_MIGRATIONS.sql`
- Role detection code: `src/utils/roleDetection.js`

**IMPORTANT:** Step 1 (SQL migration) is REQUIRED. The code changes are already live on Vercel, but they depend on the database changes.

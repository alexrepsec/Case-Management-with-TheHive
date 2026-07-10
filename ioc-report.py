#!/usr/bin/env python3
# =============================================================
# ioc-report.py — TheHive IOC Report Generator
# Author: alexrepsec | github.com/alexrepsec
# Description: Connects to TheHive API and exports IOCs
#              from a case into a structured report
# Usage: python3 ioc-report.py --case 1
# =============================================================

import argparse
import json
import sys
from datetime import datetime

try:
    import requests
    from requests.auth import HTTPBasicAuth
except ImportError:
    print("[!] requests library not found. Run: pip install requests")
    sys.exit(1)

# ── Config ────────────────────────────────────────────────────
THEHIVE_URL  = "http://localhost:9000"
API_KEY      = "your-analyst-api-key-here"
HEADERS      = {
    "Authorization": f"Bearer {API_KEY}",
    "Content-Type":  "application/json"
}

# ── Helpers ───────────────────────────────────────────────────
def get_case(case_id: int) -> dict:
    url = f"{THEHIVE_URL}/api/v1/case/{case_id}"
    r = requests.get(url, headers=HEADERS, timeout=10)
    r.raise_for_status()
    return r.json()

def get_observables(case_id: int) -> list:
    url = f"{THEHIVE_URL}/api/v1/case/{case_id}/observable"
    r = requests.get(url, headers=HEADERS, timeout=10)
    r.raise_for_status()
    return r.json()

def get_tasks(case_id: int) -> list:
    url = f"{THEHIVE_URL}/api/v1/case/{case_id}/task"
    r = requests.get(url, headers=HEADERS, timeout=10)
    r.raise_for_status()
    return r.json()

def format_timestamp(ms: int) -> str:
    if not ms:
        return "N/A"
    return datetime.utcfromtimestamp(ms / 1000).strftime("%Y-%m-%d %H:%M:%S UTC")

# ── Report ────────────────────────────────────────────────────
def generate_report(case_id: int):
    print(f"\n{'='*60}")
    print(f"  TheHive IOC Report — Case #{case_id}")
    print(f"  Generated: {datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S UTC')}")
    print(f"{'='*60}\n")

    # Case details
    try:
        case = get_case(case_id)
    except requests.exceptions.ConnectionError:
        print("[!] Cannot connect to TheHive. Is the stack running?")
        sys.exit(1)
    except requests.exceptions.HTTPError as e:
        print(f"[!] HTTP error: {e}")
        sys.exit(1)

    print(f"[CASE DETAILS]")
    print(f"  Title      : {case.get('title', 'N/A')}")
    print(f"  Severity   : {case.get('severity', 'N/A')}")
    print(f"  Status     : {case.get('status', 'N/A')}")
    print(f"  TLP        : {case.get('tlp', 'N/A')}")
    print(f"  Start Date : {format_timestamp(case.get('startDate'))}")
    print(f"  End Date   : {format_timestamp(case.get('endDate'))}")
    print(f"  Summary    : {case.get('summary', 'N/A')}")
    print()

    # Observables / IOCs
    observables = get_observables(case_id)
    print(f"[IOCs — {len(observables)} observables]\n")
    print(f"  {'TYPE':<12} {'VALUE':<30} {'TAGS':<25} {'IOC'}")
    print(f"  {'-'*12} {'-'*30} {'-'*25} {'-'*5}")
    for obs in observables:
        data_type = obs.get("dataType", "N/A")
        data      = obs.get("data", "N/A")
        tags      = ", ".join(obs.get("tags", []))
        is_ioc    = "YES" if obs.get("ioc") else "NO"
        print(f"  {data_type:<12} {data:<30} {tags:<25} {is_ioc}")
    print()

    # Tasks
    tasks = get_tasks(case_id)
    print(f"[TASKS — {len(tasks)} tasks]\n")
    print(f"  {'TITLE':<45} {'GROUP':<15} {'STATUS'}")
    print(f"  {'-'*45} {'-'*15} {'-'*10}")
    for task in tasks:
        title  = task.get("title", "N/A")[:44]
        group  = task.get("group", "N/A")
        status = task.get("status", "N/A")
        print(f"  {title:<45} {group:<15} {status}")
    print()

    # Export to JSON
    report = {
        "generated_at": datetime.utcnow().isoformat(),
        "case": case,
        "observables": observables,
        "tasks": tasks
    }
    filename = f"ioc-report-case-{case_id}.json"
    with open(filename, "w") as f:
        json.dump(report, f, indent=2)
    print(f"[+] Full report exported to: {filename}")
    print(f"{'='*60}\n")

# ── Entry Point ───────────────────────────────────────────────
if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="TheHive IOC Report Generator — Operation Phantom Harvest"
    )
    parser.add_argument(
        "--case", type=int, required=True,
        help="TheHive case ID (e.g. --case 1)"
    )
    args = parser.parse_args()
    generate_report(args.case)

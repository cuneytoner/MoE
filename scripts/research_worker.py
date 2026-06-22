#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Script Name:  research_worker.py
Description:  Autonomous background web crawler running on PC-2 to ingest,
              clean, and generate synthesis files for PC-1 RAG architecture.
"""

import sys
import os
import requests
from bs4 import BeautifulSoup
from datetime import datetime

def perform_deep_research(topic_query):
    print(f"[{datetime.now()}] Starting autonomous web research for: {topic_query}")
    search_url = f"https://duckduckgo.com{requests.utils.quote(topic_query)}"
    headers = {"User-Agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/119.0"}
    
    try:
        response = requests.get(search_url, headers=headers, timeout=15)
        if response.status_code != 200:
            print(f"[ERROR] Failed to fetch search results. Status: {response.status_code}")
            return
            
        soup = BeautifulSoup(response.text, 'html.parser')
        links = []
        for a in soup.find_all('a', class_='result__url'):
            href = a.get('href')
            if href and "duckduckgo.com" not in href:
                links.append(href)
                
        print(f"[INFO] Discovered {len(links)} endpoints. Parsing content...")
        
        filename = f"research_{int(datetime.now().timestamp())}.md"
        with open(filename, "w", encoding="utf-8") as f:
            f.write(f"# Autonomous Deep Research Report: {topic_query}\n")
            f.write(f"Generated on: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')} UTC\n\n")
            
            for idx, link in enumerate(links[:5]):
                try:
                    page_res = requests.get(link, headers=headers, timeout=10)
                    page_soup = BeautifulSoup(page_res.text, 'html.parser')
                    for element in page_soup(["script", "style", "nav", "footer", "header"]):
                        element.decompose()
                    paragraphs = [p.get_text().strip() for p in page_soup.find_all('p') if len(p.get_text().strip()) > 40]
                    f.write(f"### Source [{idx+1}]: {link}\n{' '.join(paragraphs[:10])}\n\n---\n\n")
                except Exception as e:
                    pass
        print(f"[SUCCESS] Research complete: {filename}")
    except Exception as e:
        print(f"[CRITICAL ERROR] Failed: {e}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 research_worker.py '<topic>'")
        sys.exit(1)
    perform_deep_research(sys.argv[1])

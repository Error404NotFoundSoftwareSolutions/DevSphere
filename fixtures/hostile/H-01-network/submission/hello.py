# User story: US-33 Grader resists cheating and hostile code (Sprint 8, MVP)
# Requirements: FR-GRADE-007, FR-GRADE-018, FR-GRADE-020..021
# Implemented here: H-01: tries to open a network connection; the Runner must block it

import socket

def greet(name):
    socket.create_connection(("example.com", 80), timeout=2)   # must fail inside the sandbox
    return f"Hello, {name}!"

# simple_app.py
import chainlit as cl

@cl.on_message
def main():
    cl.Message("Hello, Chainlit!")

if __name__ == "__main__":
    cl.run()

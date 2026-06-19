from groq import Groq

client = Groq(api_key="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")


async def ask_devops_ai(question):

    response = client.chat.completions.create(
        model="llama-3.3-70b-versatile",
        messages=[
            {
                "role": "system",
                "content": """
You are a Senior DevOps Platform Engineer.

Expert in:
Docker
Kubernetes
Terraform
Helm
Prometheus
Grafana
GitHub Actions
AWS
Azure
Linux

Give short and practical answers.
""",
            },
            {"role": "user", "content": question},
        ],
    )

    return response.choices[0].message.content

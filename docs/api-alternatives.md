---
project: fluffy-train
status: done
---

# Tech Spec: Social Media API Alternatives & Strategy Pivot

**Status:** Proposed
**Owner:** Tim Lawrenz
**Last Updated:** 2025-09-21

## 1. Overview

During the initial real-world testing of Milestone 1, a critical blocker was identified: the Buffer API no longer supports the creation of new developer applications. This prevents the project from authenticating with and using the Buffer API as originally planned.

This document summarizes the research into alternative APIs and proposes a new technical strategy for the project's social media integration.

## 2. Research Findings

An investigation was conducted into viable alternatives for scheduling posts to Instagram. The key requirements were a developer-friendly API, the ability to schedule posts, and the ability to retrieve engagement data.

### 2.1. Buffer
*   **Findings:** Confirmed that Buffer has discontinued their program for new developer apps.
*   **Conclusion:** Not a viable option for this project.

### 2.2. Later
*   **Findings:** Later does not offer a public-facing developer API. It is a consumer product that *uses* the Instagram API, rather than providing one.
*   **Conclusion:** Not a viable option.

### 2.3. Hootsuite
*   **Findings:** Hootsuite provides a comprehensive developer API. However, authentication is based on the full OAuth 2.0 protocol. This requires registering a developer application, building a web-based authorization flow (including handling redirects and callbacks), and managing access/refresh tokens.
*   **Conclusion:** A viable, but complex, option. The level of effort is comparable to a direct integration with Instagram.

### 2.4. Instagram Graph API (Meta for Developers)
*   **Findings:** This is the official and most direct API for interacting with Instagram Business and Creator accounts. It is the underlying API that services like Buffer, Later, and Hootsuite use. Authentication is also based on OAuth 2.0 and requires a similar setup to Hootsuite (app registration, web flow, token management).
*   **Conclusion:** The most powerful and sustainable long-term option. It provides the most direct access to Instagram's features and analytics without relying on a third-party intermediary.

## 3. Strategic Recommendation

All viable, long-term solutions require a full OAuth 2.0 implementation. Attempting to find a "simple" API without this requirement has proven to be a dead end.

Therefore, the recommendation is to **pivot the project to use the official Instagram Graph API directly.**

While this introduces significant new work, it has several advantages:
*   **No Third-Party Dependency:** The project will not be subject to the changing business decisions or API access policies of a middleman service.
*   **Full Feature Access:** Direct integration provides access to the complete feature set of the Instagram API, including the latest updates for Reels, Stories, and detailed analytics.
*   **Long-Term Viability:** Building on the official platform is the most stable and future-proof approach.

## 4. Impact on Roadmap & Next Steps

This pivot requires a significant change to the project's architecture and roadmap. The immediate next steps are no longer related to photo analysis, but to building the core infrastructure for authentication.

### 4.1. New "Milestone 1.5": Web Server & Instagram Authentication

A new, intermediate milestone is required to build the foundational web components.

*   **1. Add a Web Server:** Integrate a lightweight web server (e.g., Puma/Sinatra, or use the existing Rails server) to handle HTTP requests.
*   **2. Build the OAuth 2.0 Flow:**
    *   Create a developer application in the Meta Developer Portal.
    *   Implement the server-side logic to handle the OAuth 2.0 authorization flow (redirect to Instagram, handle the callback, exchange the authorization code for an access token).
    *   Create a new data model (e.g., `User` or `Account`) to securely store the `access_token` and `refresh_token` for each authenticated user.
*   **3. Refactor the API Client:**
    *   Rename `Buffer::Client` to `Instagram::Client`.
    *   Update the client to use the stored `access_token` for API requests to the Instagram Graph API.
    *   Implement the necessary API calls for scheduling a photo post.

## 5. Non-Technical Requirements & Process

Before beginning development, it's important to understand the non-technical requirements for using the Instagram Graph API.

### 5.1. Fees and Costs
*   **Direct API Usage:** The Instagram Graph API is **free to use**. Meta does not charge for API access.
*   **Indirect Costs:** The primary constraint is **rate limiting** (a limit on how many API calls can be made in a given time). For a personal automation tool, it is highly unlikely these limits will be a factor.

### 5.2. Application & Review Process
The process for a personal-use tool is significantly simpler than for a public application.

*   **Prerequisites:**
    1.  An **Instagram Business or Creator Account** is required.
    2.  The Instagram account must be **linked to a Facebook Page**.
    3.  A **Meta Developer Account** must be created.

*   **"Development Mode" is Sufficient:**
    *   By default, all new Meta apps start in **"Development Mode"**.
    *   In this mode, the app is fully functional but can only be used by registered administrators, developers, or testers (i.e., your own account).
    *   For the purposes of this project (automating your own posts), the app can remain in Development Mode indefinitely.
    *   Crucially, apps in Development Mode **do not need to be submitted for a formal App Review process.**

*   **"Live Mode" (Not Required):**
    *   If this tool were to be distributed for others to use, it would need to be switched to "Live Mode," which requires a formal review and approval from Meta. This is not necessary for the project's current scope.

### 5.3. Business Verification & Policies
*   **Business Verification:** Not required for this use case.
*   **Privacy Policy:** During app setup, you will be required to provide a URL for a privacy policy. For a personal tool, a simple, publicly accessible page explaining the tool's purpose and data handling is sufficient.

### 5.4. Local Development Using `localhost`
A key advantage of keeping the application in "Development Mode" is the ability to use `localhost` for the OAuth Redirect URI. Meta's platform explicitly allows this for development purposes, which means you can build and test the entire authentication flow on your local machine without needing to deploy to a public server.

During the app setup, you can specify a redirect URI like:
`http://localhost:3000/auth/instagram/callback`

This is sufficient for the project's entire lifecycle, as it will remain in Development Mode. If the app were ever to be switched to "Live Mode," Meta would require this be changed to a valid, public HTTPS URL.

### Conclusion for This Project
The path forward with the official Instagram API is clear. It is free, and by operating in "Development Mode," we can avoid the complex and lengthy formal App Review process, making it a highly viable solution.

## 6. Implementation Status & Next Steps

**As of 2025-09-21, the project is paused pending Meta Business Verification.**

The process to acquire API access was initiated, which involved:
1.  Creating a Meta Developer Account and a new app.
2.  Attempting to add the necessary permissions (`instagram_content_publish`) to the app.

This action triggered a mandatory **Business Verification** requirement from Meta. The necessary documents have been submitted, and we are awaiting approval, which may take up to two days.

### Immediate Next Steps (Post-Verification)

Once Meta approves the Business Verification, the following actions are required to complete the API setup:

1.  **Generate Access Token:** Use the Graph API Explorer to generate a short-lived User Access Token with the required permissions.
2.  **Obtain Long-Lived Token:** Immediately exchange the short-lived token for a long-lived token (valid for 60 days) via an API call.
3.  **Retrieve Instagram Account ID:** Use the long-lived token to fetch the specific ID for the Instagram Business Account that will be used for posting.
4.  **Collect App Credentials:** Securely copy the **App ID** and **App Secret** from the Meta Developer App's "Basic Settings" page.
5.  **Begin Code Implementation:** With all credentials and IDs collected, proceed with building the OAuth 2.0 logic within the Rails application as outlined in "Milestone 1.5".

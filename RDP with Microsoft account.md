# Remote Desktop or Network Shares with Microsoft Account Sign-In

If you sign in to your PC using a Microsoft Account, you may face issues connecting to Remote Desktop or network file sharing. Here's how to fix it:

## Method One: Quick & Easy Way

On the PC hosting the remote desktop session (running Windows Pro or better), run the following command, replacing the example email address with your Microsoft Account email address:

```bash
runas /u:MicrosoftAccount\username@example.com winver
```

After supplying the password, you should see the About Windows dialog box open, indicating success.

Login with username: MicrosoftAccount\youruser@domain.com

## Method Two: Alternative (Slight Hassle) Way
Another way is to unlink your Microsoft Account, set a local password, and then relink the account. Here are the steps:

Go to Settings > Accounts > Your Info, click “Sign in with a local account instead” and set a password.

Restart your computer and verify you can connect using the local account credentials.

Optionally, relink the account to your Microsoft Account.

Don’t Forget Your Network Type

Ensure your Network Type is set to "Private" to allow RDP connections. Open File Explorer, click Network, set your Network Type as “Private” if needed.

Remote Desktop From Outside Your Home
Consider using Google Chrome Remote Desktop for more secure and functional remote desktop connections.

Original article https://cmdrkeene.com/remote-desktop-with-microsoft-account-sign-in/

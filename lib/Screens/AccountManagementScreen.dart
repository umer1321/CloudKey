import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../routes.dart';

class AccountManagementScreen extends StatefulWidget {
  const AccountManagementScreen({super.key});

  @override
  State<AccountManagementScreen> createState() => _AccountManagementScreenState();
}

class _AccountManagementScreenState extends State<AccountManagementScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? user;
  Map<String, dynamic>? userData;
  bool isLoading = true;
  bool isUpdating = false;
  String? errorMessage;

  // Controllers for editable fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;
    if (user != null) {
      _fetchUserData();
    } else {
      setState(() {
        isLoading = false;
        errorMessage = 'Please log in to manage your account.';
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, Routes.auth);
      });
    }
  }

  Future<void> _fetchUserData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(user!.uid).get();
      if (doc.exists) {
        setState(() {
          userData = doc.data() as Map<String, dynamic>;
          _nameController.text = userData?['name'] ?? '';
          _emailController.text = user?.email ?? '';
          _phoneController.text = userData?['phoneNumber'] ?? '';
          isLoading = false;
        });
      } else {
        await _firestore.collection('users').doc(user!.uid).set({
          'email': user!.email,
          'name': user!.displayName ?? '',
          'phoneNumber': '',
          'createdAt': Timestamp.now(),
        });
        setState(() {
          userData = {
            'email': user!.email,
            'name': user!.displayName ?? '',
            'phoneNumber': '',
            'createdAt': Timestamp.now(),
          };
          _nameController.text = userData?['name'] ?? '';
          _emailController.text = user?.email ?? '';
          _phoneController.text = userData?['phoneNumber'] ?? '';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error fetching user data: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching user data: $e')),
      );
    }
  }

  Future<bool> _reAuthenticate() async {
    String? currentPassword = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Re-authenticate'),
        content: TextField(
          controller: _currentPasswordController,
          decoration: const InputDecoration(
            labelText: 'Current Password',
            border: OutlineInputBorder(),
          ),
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _currentPasswordController.text),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (currentPassword == null || currentPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your current password.')),
      );
      return false;
    }

    try {
      AuthCredential credential = EmailAuthProvider.credential(
        email: user!.email!,
        password: currentPassword,
      );
      await user!.reauthenticateWithCredential(credential);
      return true;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Re-authentication failed: $e')),
      );
      return false;
    }
  }

  Future<void> _updateAccount() async {
    if (user == null) return;

    setState(() {
      isUpdating = true;
      errorMessage = null;
    });

    try {
      bool needsReAuth = _emailController.text != user!.email || _passwordController.text.isNotEmpty;

      if (needsReAuth) {
        bool reAuthenticated = await _reAuthenticate();
        if (!reAuthenticated) {
          setState(() {
            isUpdating = false;
            errorMessage = 'Re-authentication required to update email or password.';
          });
          return;
        }

        // Update email if changed
        if (_emailController.text != user!.email) {
          await user!.updateEmail(_emailController.text);
        }

        // Update password if provided
        if (_passwordController.text.isNotEmpty) {
          await user!.updatePassword(_passwordController.text);
        }

        // Reload user to ensure changes are applied
        await user!.reload();
        user = _auth.currentUser;
      }

      // Update Firestore user document
      await _firestore.collection('users').doc(user!.uid).update({
        'email': _emailController.text,
        'name': _nameController.text,
        'phoneNumber': _phoneController.text,
      });

      setState(() {
        isUpdating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account updated successfully!')),
      );

      // Refresh user data
      await _fetchUserData();
    } catch (e) {
      setState(() {
        isUpdating = false;
        errorMessage = 'Error updating account: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating account: $e')),
      );
    }
  }

  Future<void> _deleteAccount() async {
    if (user == null) return;

    try {
      // Show confirmation dialog
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Account'),
          content: const Text('Are you sure you want to delete your account? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      // Re-authenticate before deleting
      bool reAuthenticated = await _reAuthenticate();
      if (!reAuthenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Re-authentication required to delete account.')),
        );
        return;
      }

      // Delete Firestore user document
      await _firestore.collection('users').doc(user!.uid).delete();

      // Delete Firebase Authentication account
      await user!.delete();

      // Sign out and redirect to auth screen
      await _auth.signOut();
      Navigator.pushReplacementNamed(context, Routes.auth);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account deleted successfully.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting account: $e')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _currentPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Management'),
        backgroundColor: Colors.brown,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            const Text(
              'Account Information',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'New Password (leave blank to keep current)',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 30),
            isUpdating
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
              onPressed: _updateAccount,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Update Account',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _deleteAccount,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Delete Account',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../core/api.dart';
import '../widgets/common.dart';
import 'register_screen.dart';
import 'catalog_screen.dart';

class LoginScreen extends StatefulWidget { const LoginScreen({super.key});
  @override State<LoginScreen> createState()=> _LoginScreenState(); }

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController(text: 'cliente@demo.cl');
  final _pass = TextEditingController(text: 'demo1234');
  bool _busy=false;

  Future<void> _doLogin() async {
    setState(()=>_busy=true);
    final err = await Api.login(_email.text.trim(), _pass.text);
    setState(()=>_busy=false);
    if (!mounted) return;
    if (err!=null) { ScaffoldMessenger.of(context).showSnackBar(ko(err)); }
    else { Navigator.pushReplacementNamed(context, CatalogScreen.route); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('ARTattoo', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
                const Gap(18),
                TextField(controller:_email, decoration: const InputDecoration(labelText:'Email', prefixIcon: Icon(Icons.alternate_email))),
                const Gap(12),
                TextField(controller:_pass, obscureText:true, decoration: const InputDecoration(labelText:'Password', prefixIcon: Icon(Icons.lock_outline))),
                const Gap(18),
                FilledButton(onPressed:_busy?null:_doLogin, child:_busy? const SizedBox(height:18,width:18,child:CircularProgressIndicator(strokeWidth:2)) : const Text('Entrar')),
                const Gap(6),
                TextButton(onPressed: ()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> const RegisterScreen())), child: const Text('Crear cuenta')),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

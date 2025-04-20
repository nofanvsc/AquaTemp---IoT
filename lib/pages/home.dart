import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: 
        Column(
          children: [
            TopNav(),
            Content(),
            BottomNav()
            
          ],
        ),
     

      ),
    );
  }
}


class TopNav extends StatelessWidget {
  const TopNav({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(padding: EdgeInsets.all(8.0), child: Placeholder());
  }
}

class Content extends StatelessWidget {
  const Content({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(padding: EdgeInsets.all(8.0), child: Placeholder());
  }
}

class BottomNav extends StatelessWidget {
  const BottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(padding: EdgeInsets.all(8.0), child: Placeholder());
  }
}
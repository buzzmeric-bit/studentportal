import 'package:flutter/services.dart';

/// Text formatter that capitalizes the first letter of each word
/// Useful for names, places, and other proper nouns
class CapitalizeWordsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final String formatted = _capitalizeWords(newValue.text);
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _capitalizeWords(String text) {
    if (text.isEmpty) return text;
    
    // Split by spaces and hyphens, but preserve them
    final parts = <String>[];
    final buffer = StringBuffer();
    
    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      
      if (char == ' ' || char == '-') {
        if (buffer.isNotEmpty) {
          parts.add(_capitalizeWord(buffer.toString()));
          buffer.clear();
        }
        parts.add(char);
      } else {
        buffer.write(char);
      }
    }
    
    if (buffer.isNotEmpty) {
      parts.add(_capitalizeWord(buffer.toString()));
    }
    
    return parts.join();
  }

  String _capitalizeWord(String word) {
    if (word.isEmpty) return word;
    
    // Handle special cases for French articles and particles
    final lowerWord = word.toLowerCase();
    if (_isSmallWord(lowerWord) && word.length > 1) {
      return lowerWord;
    }
    
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }

  bool _isSmallWord(String word) {
    // Small words that should remain lowercase (except at start)
    const smallWords = {
      'de', 'du', 'des', 'le', 'la', 'les', 'un', 'une',
      'd', 'l', 'et', 'à', 'au', 'aux', 'en', 'sur', 'dans'
    };
    return smallWords.contains(word);
  }
}

/// Text formatter specifically for names (first name, last name)
/// Only capitalizes the first letter
class CapitalizeFirstLetterFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final String formatted = newValue.text[0].toUpperCase() + 
                            newValue.text.substring(1).toLowerCase();
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

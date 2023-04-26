import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:keep_screen_on/keep_screen_on.dart';
import 'package:audio_session/audio_session.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:flutter/material.dart';


final Logger _logger = Logger('MyApp');


void main() async {
  
  //carregar variáveis ​​de ambiente
  await dotenv.load(fileName: ".env");

  // não durma
  KeepScreenOn.turnOn();
  
  //initializeDateFormatting();
  Intl.defaultLocale = 'pt_BR';

  //Configurações de localidade/idioma (iOS corrigido com Info.plist)
  Intl.withLocale('pt', () => 

    runApp(const MyApp())
  );
}


class SettingView extends StatefulWidget {

  const SettingView({super.key});

  @override
  State<SettingView> createState() => _SettingViewState();
}

class _SettingViewState extends State<SettingView> {
  String _selectedItemMy = "error";
  String _selectedItemBot = "error";
  final List<String> _items = ["error"];
  final FlutterTts tts = FlutterTts();
  late SharedPreferences prefs;

  @override
  void initState() {
    super.initState();

    Future(() async {

      prefs = await SharedPreferences.getInstance();

      List voices = await tts.getVoices;

      _items.clear();
      for(var item in voices){
        var map = item as Map<Object?, Object?>;
        if(map["locale"].toString().toLowerCase().contains("pt")){
          _logger.info(map["name"]);
          _items.add(map["name"].toString());
        }
      }
      if(_items.isNotEmpty){
        
        _selectedItemMy = prefs.getString("voice_EU") ?? _items[0];
        _selectedItemBot = prefs.getString("voice_robô") ?? _items[0];
      }

      // refletir puxar para baixo
      setState(() {});
      
    });
  }

  Future<void> _changeVoice(String voiceName, String who, bool speak) async {

    prefs.setString("voice_$who", voiceName);

    if(!speak)
    {
      return;
    }

    await tts.stop();
    await tts.setVoice({
      'name': voiceName,
      'locale': 'pt-BR'
    });
    
    await tts.speak("$who voz foi definida");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("Setting"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('voice_EU'),
            DropdownButton<String>(
              value: _selectedItemMy,
              items: _items
                  .map((String list) =>
                      DropdownMenuItem(value: list, child: Text(list)))
                  .toList(),
              onChanged: (String? value) {
                setState(() {
                  _selectedItemMy = value!;
                  _changeVoice(_selectedItemMy, "Eu", true);
                });
              },
            ),
            const Divider(height: 100),

            const Text('voz de robô'),
            DropdownButton<String>(
              value: _selectedItemBot,
              items: _items
                  .map((String list) =>
                      DropdownMenuItem(value: list, child: Text(list)))
                  .toList(),
              onChanged: (String? value) {
                setState(() {
                  _selectedItemBot = value!;
                  _changeVoice(_selectedItemBot, "robô", true);
                });
              },
            ),
          ]
        )
      ),
    );
  }
}

class CompleteForm extends StatefulWidget {
  const CompleteForm({Key? key}) : super(key: key);

  @override
  State<CompleteForm> createState() {
    return _CompleteFormState();
  }
}

class _CompleteFormState extends State<CompleteForm> {
  bool autoValidate = true;
  bool readOnly = false;
  bool showSegmentedControl = true;
  final _formKey = GlobalKey<FormBuilderState>();
  bool _ageHasError = false;
  bool _genderHasError = false;

  var genderOptions = ['Menino', 'Menina', 'Outro'];

  void _onChanged(dynamic val) => debugPrint(val.toString());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Form Builder Example')),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              FormBuilder(
                key: _formKey,
                // enabled: false,
                onChanged: () {
                  _formKey.currentState!.save();
                  debugPrint(_formKey.currentState!.value.toString());
                },
                autovalidateMode: AutovalidateMode.disabled,
                initialValue: const {
                  'movie_rating': 5,
                  'best_language': 'Dart',
                  'age': '13',
                  'gender': 'Menino',
                  'languages_filter': ['Dart']
                },
                skipDisabled: true,
                child: Column(
                  children: <Widget>[
                    const SizedBox(height: 15),
                    FormBuilderSlider(
                      name: 'slider',
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.min(6),
                      ]),
                      onChanged: _onChanged,
                      min: 0.0,
                      max: 10.0,
                      initialValue: 7.0,
                      divisions: 20,
                      activeColor: Colors.red,
                      inactiveColor: Colors.pink[100],
                      decoration: const InputDecoration(
                        labelText: 'Duração da história',
                      ),
                    ),
                    FormBuilderTextField(
                      autovalidateMode: AutovalidateMode.always,
                      name: 'age',
                      decoration: InputDecoration(
                        labelText: 'Age',
                        suffixIcon: _ageHasError
                            ? const Icon(Icons.error, color: Colors.red)
                            : const Icon(Icons.check, color: Colors.green),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _ageHasError = !(_formKey.currentState?.fields['age']
                                  ?.validate() ??
                              false);
                        });
                      },
                      // valueTransformer: (text) => num.tryParse(text),
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                        FormBuilderValidators.numeric(),
                        FormBuilderValidators.max(70),
                      ]),
                      // initialValue: '12',
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                    ),
                    FormBuilderDropdown<String>(
                      name: 'gender',
                      decoration: InputDecoration(
                        labelText: 'Gênero',
                        suffix: _genderHasError
                            ? const Icon(Icons.error)
                            : const Icon(Icons.check),
                        hintText: 'Selecionar Gênero',
                      ),
                      validator: FormBuilderValidators.compose(
                          [FormBuilderValidators.required()]),
                      items: genderOptions
                          .map((gender) => DropdownMenuItem(
                                alignment: AlignmentDirectional.center,
                                value: gender,
                                child: Text(gender),
                              ))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _genderHasError = !(_formKey
                                  .currentState?.fields['gender']
                                  ?.validate() ??
                              false);
                        });
                      },
                      valueTransformer: (val) => val?.toString(),
                    ),
                    FormBuilderSegmentedControl(
                      decoration: const InputDecoration(
                        labelText: 'Gênero',
                      ),
                      name: 'movie_rating',
                      // initialValue: 1,
                      // textStyle: TextStyle(fontWeight: FontWeight.bold),
                      //options: List.generate(5, (i) => i + 1)
                      options: ['Comédia', 'Calmo', 'Aventura', 'Swift', 'Terror'].map((number) => FormBuilderFieldOption(
                                value: number,
                                child: Text(
                                  number.toString(),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ))
                          .toList(),
                      onChanged: _onChanged,
                    ),
                    FormBuilderSwitch(
                      title: const Text('I Accept the terms and conditions'),
                      name: 'accept_terms_switch',
                      initialValue: true,
                      onChanged: _onChanged,
                    ),
                    FormBuilderCheckboxGroup<String>(
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: const InputDecoration(
                          labelText: 'The language of my people'),
                      name: 'languages',
                      // initialValue: const ['Dart'],
                      options: const [
                        FormBuilderFieldOption(value: 'Dart'),
                        FormBuilderFieldOption(value: 'Kotlin'),
                        FormBuilderFieldOption(value: 'Java'),
                        FormBuilderFieldOption(value: 'Swift'),
                        FormBuilderFieldOption(value: 'Objective-C'),
                      ],
                      onChanged: _onChanged,
                      separator: const VerticalDivider(
                        width: 10,
                        thickness: 5,
                        color: Colors.red,
                      ),
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.minLength(1),
                        FormBuilderValidators.maxLength(3),
                      ]),
                    ),
                    FormBuilderFilterChip<String>(
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: const InputDecoration(
                          labelText: 'Personagens'),
                      name: 'languages_filter',
                      selectedColor: Color.fromARGB(255, 91, 110, 194),
                      options: const [
                        FormBuilderChipOption(
                          value: 'Homem Aranha',
                          avatar: CircleAvatar(child: Text('HA')),
                        ),
                        FormBuilderChipOption(
                          value: 'Hulk',
                          avatar: CircleAvatar(child: Text('HU')),
                        ),
                        FormBuilderChipOption(
                          value: 'Homem de Ferro',
                          avatar: CircleAvatar(child: Text('HF')),
                        ),
                        FormBuilderChipOption(
                          value: 'Capitão América',
                          avatar: CircleAvatar(child: Text('CA')),
                        ),
                        FormBuilderChipOption(
                          value: 'Pantera Negra',
                          avatar: CircleAvatar(child: Text('PN')),
                        ),
                      ],
                      onChanged: _onChanged,
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.minLength(1),
                        FormBuilderValidators.maxLength(4),
                      ]),
                    ),
                    FormBuilderChoiceChip<String>(
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: const InputDecoration(
                          labelText:
                              'Ok, if I had to choose one language, it would be:'),
                      name: 'languages_choice',
                      initialValue: 'Dart',
                      options: const [
                        FormBuilderChipOption(
                          value: 'Dart',
                          avatar: CircleAvatar(child: Text('D')),
                        ),
                        FormBuilderChipOption(
                          value: 'Kotlin',
                          avatar: CircleAvatar(child: Text('K')),
                        ),
                        FormBuilderChipOption(
                          value: 'Java',
                          avatar: CircleAvatar(child: Text('J')),
                        ),
                        FormBuilderChipOption(
                          value: 'Swift',
                          avatar: CircleAvatar(child: Text('S')),
                        ),
                        FormBuilderChipOption(
                          value: 'Objective-C',
                          avatar: CircleAvatar(child: Text('O')),
                        ),
                      ],
                      onChanged: _onChanged,
                    ),
                  ],
                ),
              ),
              Row(
                children: <Widget>[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState?.saveAndValidate() ?? false) {
                          debugPrint(_formKey.currentState?.value.toString());
                        } else {
                          debugPrint(_formKey.currentState?.value.toString());
                          debugPrint('validation failed');
                        }
                      },
                      child: const Text(
                        'Submit',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _formKey.currentState?.reset();
                      },
                      // color: Theme.of(context).colorScheme.secondary,
                      child: Text(
                        'Reset',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Speak Chat',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      //home: const MyHomePage(title: 'Speak Chat'),
      home: CompleteForm (),
      //ロケール・言語設定（iOSはInfo.plistで直った）
      localizationsDelegates: const [
        // localizations delegateを追加
        //AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      
      //ロケール・言語設定（iOSはInfo.plistで直った）
      supportedLocales: const [Locale('pt', 'BR')],
      locale: const Locale('pt', 'BR'),

    );
  }
  
}


class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}


class _MyHomePageState extends State<MyHomePage> {
  String lastWords = '';
  String systemRole = "Você é uma terapeuta que aplica técnicas de Coaching, constelação sistêmica e Programação Neuro Linguística. Você utiliza a terapia cognitivo comportamental como aporte científico. Aplica técnicas de coaching e PNL como estratégias alternativas no trabalho de desenvolvimento de cada indivíduo. Você domina os conteúdos de Coaching para aplicar na sua vida e carreira ou para desenvolver em programas de maximização de performance humana. Você é capaz de capacitar o cliente a tomar decisões, desenvolver habilidades e alcançar seus objetivos de forma independente. Você se comunica claramente e efetivamente com o cliente, usando técnicas de linguagem positiva e construtiva. Você se coloca no lugar do cliente e entender suas emoções e pontos de vista. Você responde com no máximo 100 palavras. Se necessário mais detalhes será requisitado";

  
  List<Object> chatMessages = [];
  final FlutterTts tts = FlutterTts();
  late SharedPreferences prefs;
  var inputTextcontroller = TextEditingController();
  ScrollController scrollController = ScrollController();


  @override
  void initState() {
    super.initState();


    Future(() async {

      prefs = await SharedPreferences.getInstance();

      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.speech());
      

    });

    Future(() async {
      // Defina para emitir som do alto-falante
      await tts.setIosAudioCategory(IosTextToSpeechAudioCategory.playback, [
        IosTextToSpeechAudioCategoryOptions.defaultToSpeaker
      ]);

      // Adicionar áudio à fila (somente Android)
      if(Platform.isAndroid){
        tts.setQueueMode(1);
      }

      // Configuração de velocidade de fala
      await tts.setPitch(0.9);
      await tts.setSpeechRate(1.4);
    });

    // Abra a tela de configurações
    Future(() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SettingView()),
      );
    });
  }

  String _getVoiceName(String type)
  {
    return (type == "user" ? prefs.getString("voice_EU") : prefs.getString("voice_robo"))?? "";
  }

  // Leia em voz alta
  Future<void> _speach(dynamic item) async {

    
    // pare e jogue
    await tts.stop();
    await tts.setVoice({
      'name': _getVoiceName(item["role"]),
      'locale': 'pt-BR'
    });
    
    await tts.speak(
      item["content"]
    );
  }

   // inicia a entrada de voz
  _speak()  {


    Future(() async {
      // pare de jogar
      await tts.stop();
    });

    // esvaziar a entrada
    setState(() {
      lastWords = "";
    });

    showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        
        return const SpeechDialog();
      },
    ).then((value) {

      _logger.info("end dialog!");

      setState(() {
        if(value != null){
          lastWords = value;
        }
      });


      
      _ai();



    });
  }

    



  // メッセージを消去
  Future<void> _cleanMessage() async {
    setState(() {
      chatMessages.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('mensagem apagada'),
    ));
  }
  

  // ChatGPT
  Future<void> _ai() async {
    
    _logger.info("_ai");
    
    // Ignorar se não houver entrada
    if(lastWords == "")
    {
      return;
    }

    // rolar para baixo
    scrollController.jumpTo(scrollController.position.maxScrollExtent);

    
    // pare e jogue
    await tts.stop();
    await tts.setVoice({'name': _getVoiceName("user"), 'locale': 'pt-BR'});
    // await tts.speak(
    //   lastWords
    // );
    


    // Adicionar mensagem para enviar
    chatMessages.add({"role": "user", "content": lastWords});

    setState(() {
      
      inputTextcontroller.clear();

      FocusScopeNode currentFocus = FocusScope.of(context);
      if (!currentFocus.hasPrimaryFocus) {
        currentFocus.unfocus();
      }
    });


    // Duplicar com data e hora atuais adicionadas
    List<Object> chatMessagesClone = [
      {"role": "user", "content": DateFormat('É MM mês dd dia aaaa HH hora mm').format(DateTime.now())},
      ...chatMessages
    ];

    chatMessages.add({"role": "system", "content": systemRole});

    Uri url = Uri.parse("https://api.openai.com/v1/chat/completions");
    Map<String, String> headers = {
      'Content-type': 'application/json',
      "Authorization": "Bearer ${dotenv.get("OPEN_AI_API_KEY")}"
    };
    String body = json.encode({
      "frequency_penalty": 0,
      "max_tokens": 512,
      "messages": chatMessagesClone,
      "model": "gpt-3.5-turbo",
      "presence_penalty": 0,
      "stream": true,
      "temperature": 0.7,
      "top_p": 1
    });


    final request = http.Request('POST', url);
    request.headers.addAll(headers);
    request.body = body;
    request.followRedirects = false;

    final response = await request.send();


    if(response.statusCode != 200)
    {
      setState(() {

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Ocorreu um erro de comunicação ${response.statusCode}"),
        ));
      });

      return;
    }

    _logger.info(response.statusCode);
    


    // Adicionar mensagem recebida
    chatMessages.add({"role": "assistant", "content": ""});
    setState(() {
      chatMessages = chatMessages;
    });

    var receiveMsg = "";
    var receiveMsgSpeak = "";
    var receiveDone = false;

    await for (final message in response.stream.transform(utf8.decoder)) {

      message.split("\n").forEach((msg) {

        if(!msg.startsWith("data: "))
        {
          return;
        }

        var jsonMsg = msg.replaceFirst(RegExp("^data: "), "");

        if(jsonMsg == "[DONE]")
        {
          return;
        }

        final data = json.decode(jsonMsg);
        

        var content = data["choices"][0]["delta"]["content"];
        if(content == null){
          return;
        }

        receiveMsg += content;

        receiveMsgSpeak += content;
        
        // quando ainda não acabou
        if(!receiveDone)
        {
          // Verificação do número mínimo para evitar falar em pequenas quantidades de texto
          if(receiveMsgSpeak.length > 50)
          {
            var stopIndex = receiveMsgSpeak.indexOf(RegExp("、|。|\n"), 50);
            if(stopIndex > 0)
            {
              var speackMsg = receiveMsgSpeak.substring(0, stopIndex);
              receiveMsgSpeak = receiveMsgSpeak.substring(stopIndex+1, receiveMsgSpeak.length);

              () async {
                // falar mensagem recebida
                await tts.setVoice({'name': _getVoiceName("voice_robo"), 'locale': 'pt-BR'});
                await tts.speak(
                  speackMsg
                  //receiveMsgSpeak
                );
              }();
            }
          }
        }

        // 最後に追加したデータにテキストを設定する
        dynamic item = chatMessages[chatMessages.length-1];
        item["content"] = receiveMsg;
        chatMessages[chatMessages.length-1] = item;
        
        setState(() {
          chatMessages = chatMessages;

          // rolar para baixo
          scrollController.jumpTo(scrollController.position.maxScrollExtent);
        });

      });
      
    }

    receiveDone = true;

    // rolar para baixo
    scrollController.jumpTo(scrollController.position.maxScrollExtent);
    await tts.speak(
      "Teste"
    );
    // Fale as mensagens recebidas restantes
    await tts.setVoice({'name': _getVoiceName("voice_robo"), 'locale': 'pt-BR'});
    await tts.speak(
      //receiveMsgSpeak
      receiveMsg
    );



  }


  // alterar entrada de texto
  void _handleText(String e) {
    setState(() {
      lastWords = e;
    });
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.title),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingView()),
                );
              },
            ),
          ],
      ),
      body: Column(
          
        children: <Widget>[
          
          Expanded(
            child: Padding(
            padding: const EdgeInsets.all(10),
            child: SingleChildScrollView(

                controller: scrollController,

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: chatMessages.map((dynamic item)=>(
                    GestureDetector(
                      onTap: () {
                          _speach(item);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children:[
                            Text(
                              item["role"] == "user" ? "EU　：" : "robô：",
                              style: TextStyle(
                                color: item["role"] == "user" ? Colors.blue : Colors.green, // definir a cor do texto para azul
                              ),
                            ),
                            Expanded(
                              child: Text(
                                item["content"],
                                softWrap: true,
                              )
                            )
                          ]
                        )
                      )
                    )
                  )).toList()
                )
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child:Row(
            
              children: [
                Container(
                  margin: const EdgeInsets.only(right: 10),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color.fromARGB(255, 0, 149, 255),
                    child:
                      IconButton(
                        onPressed: _cleanMessage,
                        icon: const Icon(Icons.cleaning_services),
                        iconSize: 18,
                        color:const Color.fromARGB(255, 255, 255, 255),
                      ),
                  ),
                ),
                Expanded(
                  child: 
                    TextFormField(
                      controller: inputTextcontroller,
                      enabled: true,
                      obscureText: false,
                      maxLines: null,
                      onChanged: _handleText,
                      decoration: InputDecoration(
                      suffixIcon: IconButton(
                        onPressed: _speak,
                        icon: const Icon(Icons.mic),
                      ),
                    ),
                    )
                ),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color.fromARGB(255, 0, 149, 255),
                  child:
                    IconButton(
                      onPressed: _ai,
                      icon: const Icon(Icons.send),
                      iconSize: 18,
                      color:const Color.fromARGB(255, 255, 255, 255),
                    ),
                )
              ],
            )
          )
        ],
      ),
    );
  }
}


class SpeechDialog extends StatefulWidget {
  
  const SpeechDialog({Key? key}) : super(key: key);

  @override
  SpeechDialogState createState() => SpeechDialogState();
}

class SpeechDialogState extends State<SpeechDialog> {
  String lastStatus = "";
  String lastError = "";
  String lastWords = "";
  stt.SpeechToText speech = stt.SpeechToText();
  ScrollController scrollController = ScrollController();
  double soundLevel = 0;
  



  @override
  void initState() {
    super.initState();

    
    Future(() async {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.speech());
      
    });

    Future(() async {

      // Inicializar fala
      bool available = await speech.initialize(
        onError: (SpeechRecognitionError error) {
          if(!mounted) { return; }
          setState(() {
            lastError = '${error.errorMsg} - ${error.permanent}';
          });
        },
        onStatus: (String status) {
          if(!mounted) { return; }
          setState(() {
            lastStatus = status;
            _logger.info(status);

            // rolar para baixo
            scrollController.jumpTo(scrollController.position.maxScrollExtent);
          });
        }
      );

      if (available) {
        
        
        speech.listen(onResult: (SpeechRecognitionResult result) {
          if(!mounted) { return; }
          
          setState(() {
            lastWords = result.recognizedWords;
            
          });
        },
        onSoundLevelChange:(level){

          if(!mounted) { return; }

          setState(() {
            if(lastStatus != "listening")
            {
              // TODO:No iOS, o som pronto para gravação não soa, então quero tocá-lo, mas parece que não soa no estado speech.listen (vibração também é inútil)
            }
            lastStatus = "listening";
            soundLevel = level * -1 ;
          });
        },
        localeId: "pt-BR"
        );
      } else {
        _logger.info("The user has denied the use of speech recognition.");
      }
      
    });
  }


  @override
  Widget build(BuildContext context) {
    return AlertDialog(

      title: Center(child:Text(lastStatus == "done" ? "fim" : lastStatus == "listening" ? "audição" : "em preparação $lastStatus")),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 100,
            child: SingleChildScrollView(
              controller: scrollController,
              child: Text(lastWords, style:const TextStyle(
                                color: Colors.cyan
                              ),),
            ),
          ),
          CircleAvatar(
            radius: 20 + soundLevel,
            backgroundColor: lastStatus == "listening" ? const Color.fromARGB(255, 0, 149, 255) : const Color.fromARGB(255, 128, 128, 128),
            child:
              IconButton(
                onPressed: (){

                  Navigator.of(context).pop(lastWords);
                },
                icon: const Icon(Icons.mic),
                iconSize: 18 + soundLevel,
                color:const Color.fromARGB(255, 255, 255, 255),
              ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {

    // executar as operações de limpeza necessárias
    super.dispose();

    speech.stop();
    
  }
}
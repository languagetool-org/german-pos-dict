package org.languagetool.tagging.de;

import morfologik.stemming.Dictionary;
import morfologik.stemming.DictionaryLookup;
import morfologik.stemming.IStemmer;
import morfologik.stemming.WordData;
import org.junit.Test;

import java.io.IOException;
import java.net.URISyntaxException;
import java.net.URL;
import java.util.List;

import static junit.framework.TestCase.fail;
import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.MatcherAssert.assertThat;

public class SmokeTest {
  
  @Test
  public void testDict() throws IOException, URISyntaxException {
    Dictionary dict = getDict("german.dict");
    IStemmer dictLookup = new DictionaryLookup(dict);

    List<WordData> lookup1 = dictLookup.lookup("Haus");
    assertContainsLemma("Haus", lookup1);
    assertContainsTag("SUB:AKK:SIN:NEU", lookup1);
    assertContainsTag("SUB:DAT:SIN:NEU", lookup1);
    assertContainsTag("SUB:NOM:SIN:NEU", lookup1);

    List<WordData> lookup2 = dictLookup.lookup("groß");
    assertContainsLemma("groß", lookup2);
    assertContainsTag("ADJ:PRD:GRU", lookup2);

    List<WordData> lookup2a = dictLookup.lookup("größter");
    assertContainsLemma("groß", lookup2a);
    assertContainsTag("ADJ:DAT:SIN:FEM:SUP:SOL", lookup2a);
    assertContainsTag("ADJ:GEN:PLU:FEM:SUP:SOL", lookup2a);
    assertContainsTag("ADJ:GEN:PLU:MAS:SUP:SOL", lookup2a);
    assertContainsTag("ADJ:GEN:PLU:NEU:SUP:SOL", lookup2a);
    assertContainsTag("ADJ:GEN:SIN:FEM:SUP:SOL", lookup2a);
    assertContainsTag("ADJ:NOM:SIN:MAS:SUP:IND", lookup2a);
    assertContainsTag("ADJ:NOM:SIN:MAS:SUP:SOL", lookup2a);

    List<WordData> lookup3 = dictLookup.lookup("rennen");
    assertContainsLemma("rennen", lookup3);
    assertContainsTag("VER:1:PLU:KJ1:NON", lookup3);
    assertContainsTag("VER:1:PLU:PRÄ:NON", lookup3);
    assertContainsTag("VER:3:PLU:KJ1:NON", lookup3);
    assertContainsTag("VER:3:PLU:PRÄ:NON", lookup3);
    assertContainsTag("VER:INF:NON", lookup3);
  }

  @Test
  public void testSynthesizer() throws IOException, URISyntaxException {
    Dictionary dict = getDict("german_synth.dict");
    IStemmer dictLookup = new DictionaryLookup(dict);
    List<WordData> lookup = dictLookup.lookup("Haus|SUB:AKK:SIN:NEU");
    assertThat(lookup.size(), is(1));
    assertThat(lookup.get(0).getWord().toString(), is("Haus|SUB:AKK:SIN:NEU"));
    assertThat(lookup.get(0).getStem().toString(), is("Haus"));
  }

  private void assertContainsLemma(String expectedLemma, List<WordData> lookup) {
    for (WordData wordData : lookup) {
      if (wordData.getStem().toString().equals(expectedLemma)) {
        return;
      }
    }
    fail("Expected lemma '" + expectedLemma + "' not found");
  }

  private void assertContainsTag(String expectedTag, List<WordData> lookup) {
    for (WordData wordData : lookup) {
      if (wordData.getTag().toString().equals(expectedTag)) {
        return;
      }
    }
    fail("Expected tag '" + expectedTag + "' not found");
  }

  private Dictionary getDict(String filename) throws IOException, URISyntaxException {
    URL resource = SmokeTest.class.getResource("/org/languagetool/resource/de/" + filename);
    return Dictionary.read(resource.toURI().toURL());
  }

}
